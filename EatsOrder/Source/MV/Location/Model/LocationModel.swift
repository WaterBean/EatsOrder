//
//  LocationManager.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import Combine
import CoreLocation
import Foundation
import MapKit

// MARK: - 에러 정의

/// 위치 서비스 관련 오류를 표현하는 열거형
enum LocationError: Error, Equatable {
  case permissionDenied
  case locationUnknown
  case networkError
  case geocodingFailed(String)
  case timeout
  case systemError(String)

  var localizedDescription: String {
    switch self {
    case .permissionDenied:
      return "위치 접근 권한이 없습니다. 설정에서 권한을 허용해주세요."
    case .locationUnknown:
      return "현재 위치를 확인할 수 없습니다."
    case .networkError:
      return "네트워크 연결 문제로 위치를 가져올 수 없습니다."
    case .geocodingFailed(let reason):
      return "주소 변환에 실패했습니다: \(reason)"
    case .timeout:
      return "위치 정보를 가져오는데 시간이 너무 오래 걸립니다."
    case .systemError(let message):
      return "시스템 오류: \(message)"
    }
  }

  // CLError를 LocationError로 변환하는 팩토리 메서드
  static func from(_ error: Error) -> LocationError {
    if let locationError = error as? LocationError {
      return locationError
    }

    if let clError = error as? CLError {
      switch clError.code {
      case .denied:
        return .permissionDenied
      case .locationUnknown:
        return .locationUnknown
      case .network:
        return .networkError
      case .geocodeCanceled, .geocodeFoundNoResult, .geocodeFoundPartialResult:
        return .geocodingFailed(clError.localizedDescription)
      default:
        return .systemError(clError.localizedDescription)
      }
    }

    return .systemError(error.localizedDescription)
  }
}

// MARK: - 위치 상태 정의

/// 위치 서비스 상태를 표현하는 열거형
enum LocationStatus: Equatable {
  case undetermined
  case denied
  case restricted
  case authorized
  case updating
  case error(LocationError)

  // CLAuthorizationStatus에서 LocationStatus로 변환
  static func from(_ authStatus: CLAuthorizationStatus) -> LocationStatus {
    switch authStatus {
    case .notDetermined:
      return .undetermined
    case .denied:
      return .denied
    case .restricted:
      return .restricted
    case .authorizedAlways, .authorizedWhenInUse:
      return .authorized
    @unknown default:
      return .undetermined
    }
  }
}

/// LocationModel
@MainActor
final class LocationModel: NSObject, ObservableObject {

  // 위치 매니저 인스턴스
  private let clLocationManager = CLLocationManager()
  private let geocoder = CLGeocoder()

  // 위치 정보와 상태를 관리하는 프로퍼티
  @Published private(set) var status: LocationStatus = .undetermined
  @Published private(set) var currentLocation: GeoLocation?

  // 위치 업데이트를 위한 컨티뉴에이션
  private var locationContinuation: CheckedContinuation<GeoLocation, Error>?

  // region, address, detail, cancellable 추가
  @Published var region: MKCoordinateRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 37.5133, longitude: 126.9269),
    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
  )
  @Published var address: String = "주소를 불러오는 중..."
  @Published var detail: String = ""
  private var regionCancellable: AnyCancellable?

  @Published var recentLocation: Location = Location(nickname: "창동 씨드큐브", fullAddress: "서울특별시 도봉구 창동 123-45", geoLocation: GeoLocation(coordinate: CLLocationCoordinate2D(latitude: 37.653379444362756, longitude: 127.04667442387226), address: "서울특별시 도봉구 창동 123-45"))
  private let recentLocationKey = "recentLocation"

  // 초기화
  override init() {
    super.init()
    setupLocationManager()
    checkLocationServicesStatus()
  }

  // MARK: - 내부 설정 메서드

  private func setupLocationManager() {
    clLocationManager.delegate = self
    clLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  private func checkLocationServicesStatus() {
    status = LocationStatus.from(clLocationManager.authorizationStatus)
  }

  // MARK: - LocationServiceProtocol 구현

  /// 위치 권한 요청
  func requestLocationPermission() {
    clLocationManager.requestWhenInUseAuthorization()
  }

  /// 한 번만 위치 요청 (비동기 구현)
  func requestLocation() async throws -> GeoLocation {
    checkLocationServicesStatus()

    guard status == .authorized else {
      throw LocationError.permissionDenied
    }

    return try await withCheckedThrowingContinuation { continuation in
      self.locationContinuation = continuation
      self.status = .updating
      self.clLocationManager.requestLocation()

      // 타임아웃 처리
      Task {
        try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10초 타임아웃
        if self.status == .updating {
          self.locationContinuation?.resume(throwing: LocationError.timeout)
          self.locationContinuation = nil
          self.status = .error(.timeout)
        }
      }
    }
  }

  /// 연속적인 위치 업데이트 시작
  func startUpdatingLocation() {
    checkLocationServicesStatus()

    guard status == .authorized else {
      status = .error(.permissionDenied)
      return
    }

    status = .updating
    clLocationManager.startUpdatingLocation()
  }

  /// 위치 업데이트 중지
  func stopUpdatingLocation() {
    clLocationManager.stopUpdatingLocation()

    if status == .updating {
      status = .authorized
    }
  }

  /// 주소 역 지오코딩 (위도, 경도 -> 주소 + 세부장소)
  func reverseGeocodeWithDetail(latitude: Double, longitude: Double) async throws -> (
    String, String
  ) {
    let location = CLLocation(latitude: latitude, longitude: longitude)
    return try await withCheckedThrowingContinuation { continuation in
      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let error = error {
          continuation.resume(throwing: LocationError.geocodingFailed(error.localizedDescription))
          return
        }
        guard let placemark = placemarks?.first else {
          continuation.resume(throwing: LocationError.geocodingFailed("주소를 찾을 수 없습니다."))
          return
        }
        let address = self.formatAddress(from: placemark)
        let detail = placemark.name ?? ""
        continuation.resume(returning: (address, detail))
      }
    }
  }

  /// 주소 역 지오코딩 (위도, 경도 -> 주소)
  func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
    let location = CLLocation(latitude: latitude, longitude: longitude)

    return try await withCheckedThrowingContinuation { continuation in
      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let error = error {
          continuation.resume(throwing: LocationError.geocodingFailed(error.localizedDescription))
          return
        }

        guard let placemark = placemarks?.first else {
          continuation.resume(throwing: LocationError.geocodingFailed("주소를 찾을 수 없습니다."))
          return
        }

        let address = self.formatAddress(from: placemark)
        continuation.resume(returning: address)
      }
    }
  }

  // MARK: - 편의 메서드

  /// 현재 위치의 위도와 경도를 튜플로 반환
  func getCurrentCoordinates() -> (latitude: Double, longitude: Double)? {
    guard let location = currentLocation else { return nil }
    return (latitude: location.latitude, longitude: location.longitude)
  }

  /// 오류 정보 가져오기
  func getErrorIfAny() -> LocationError? {
    if case .error(let error) = status {
      return error
    }
    return nil
  }

  // MARK: - 내부 유틸리티 메서드

  /// 플레이스마크로부터 주소 형식화
  private func formatAddress(from placemark: CLPlacemark) -> String {
    var addressComponents: [String] = []

    // 한국 주소 형식에 맞게 구성
    if let administrativeArea = placemark.administrativeArea {
      addressComponents.append(administrativeArea)
    }

    if let locality = placemark.locality {
      addressComponents.append(locality)
    }

    if let subLocality = placemark.subLocality {
      addressComponents.append(subLocality)
    }

    if let thoroughfare = placemark.thoroughfare {
      addressComponents.append(thoroughfare)
    }

    if addressComponents.isEmpty, let name = placemark.name {
      return name
    }

    return addressComponents.joined(separator: ", ")
  }

  /// 위치 정보 업데이트
  private func updateLocationData(_ location: CLLocation) async {
    do {
      let address = try await reverseGeocode(
        latitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude
      )

      let locationData = GeoLocation(coordinate: location.coordinate, address: address)

      // UI 업데이트는 메인 스레드에서
      await MainActor.run {
        self.currentLocation = locationData
        self.status = .authorized
      }

      // 컨티뉴에이션 처리
      if let continuation = locationContinuation {
        continuation.resume(returning: locationData)
        locationContinuation = nil
      }

    } catch {
      let locationError = LocationError.from(error)

      // UI 업데이트는 메인 스레드에서
      await MainActor.run {
        self.status = .error(locationError)
      }

      // 컨티뉴에이션 처리
      if let continuation = locationContinuation {
        continuation.resume(throwing: locationError)
        locationContinuation = nil
      }
    }
  }

  // region debounce 구독 시작
  func startRegionDebounce() {
    regionCancellable =
      $region
      .removeDuplicates {
        $0.center.latitude == $1.center.latitude && $0.center.longitude == $1.center.longitude
      }
      .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
      .sink { [weak self] newRegion in
        guard let self = self else { return }
        Task {
          do {
            let (address, detail) = try await self.reverseGeocodeWithDetail(
              latitude: newRegion.center.latitude, longitude: newRegion.center.longitude)
            self.address = address
            self.detail = detail
          } catch {
            self.address = "주소를 불러올 수 없습니다."
            self.detail = ""
          }
        }
      }
  }
  func cancelRegionDebounce() {
    regionCancellable?.cancel()
  }
    func saveRecentLocation(nickname: String, fullAddress: String, geoLocation: GeoLocation) {
    let location = Location(nickname: nickname, fullAddress: fullAddress, geoLocation: geoLocation)
    if let data = try? JSONEncoder().encode(location) {
      UserDefaults.standard.set(data, forKey: recentLocationKey)
      recentLocation = location
    }
  }

  func loadRecentLocation() {
    if let data = UserDefaults.standard.data(forKey: recentLocationKey),
       let location = try? JSONDecoder().decode(Location.self, from: data) {
      recentLocation = location
    }
  }
}

// MARK: - CLLocationManagerDelegate

extension LocationModel: CLLocationManagerDelegate {
  // 권한 상태가 변경되었을 때
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let newStatus = LocationStatus.from(manager.authorizationStatus)
    Task { @MainActor in
      self.status = newStatus
    }
  }

  // 위치가 업데이트되었을 때
  nonisolated func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else { return }
    Task { @MainActor in
      await self.updateLocationData(location)
    }
  }

  // 위치 업데이트 실패시
  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    let locationError = LocationError.from(error)
    Task { @MainActor in
      self.status = .error(locationError)
      if let continuation = self.locationContinuation {
        continuation.resume(throwing: locationError)
        self.locationContinuation = nil
      }
    }
  }
}

// MARK: - 확장 - SwiftUI에서 사용하기 위한 편의 메서드

extension LocationModel {
  /// 위치 권한 상태에 따른 메시지 반환
  var statusMessage: String {
    switch status {
    case .undetermined:
      return "위치 권한이 필요합니다."
    case .denied:
      return "위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."
    case .restricted:
      return "위치 서비스가 제한되었습니다."
    case .authorized:
      return "위치 권한이 허용되었습니다."
    case .updating:
      return "위치를 업데이트하는 중..."
    case .error(let error):
      return error.localizedDescription
    }
  }

  /// 현재 위치 주소 또는 기본 메시지 반환
  var currentAddress: String {
    return "위치 정보를 가져오는 중..."
  }

  /// 사용자에게 보여줄 위치 정보 요약
  var locationSummary: String {
    guard let location = currentLocation else {
      return "위치 정보 없음"
    }

    let formattedLat = String(format: "%.6f", location.latitude)
    let formattedLng = String(format: "%.6f", location.longitude)

    return "\(formattedLat), \(formattedLng)"
  }
}

// MARK: - CLLocationCoordinate2D Equatable 채택

extension CLLocationCoordinate2D: Equatable, Identifiable {
  public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
  public var id: String { "\(latitude)-\(longitude)" }
}
