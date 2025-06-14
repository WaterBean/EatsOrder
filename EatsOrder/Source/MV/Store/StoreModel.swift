//
//  StoreModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/22/25.
//

import Foundation

// MARK: - 모든 스토어 관련 액션을 정의하는 열거형
enum StoreAction {
  // 로딩 상태 액션
  case setLoading(isLoading: Bool)

  // 오류 상태 액션
  case setError(message: String?)

  // 데이터 액션
  case setMyPickStores(stores: [StoreInfo])
  case setSearchText(text: String)
  case setNextCursor(cursor: String)

  // 상태 변경 액션
  case toggleStoreLike(storeId: String)
}

// MARK: - 스토어 모델
@MainActor
final class StoreModel: ObservableObject {
  // 상태 및 데이터
  @Published private(set) var searchText: String = ""
  @Published private(set) var currentPage: Int = 0
  @Published private(set) var nextCursor: String = ""
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var error: String? = nil
  @Published var popularStores: [StoreInfo] = []
  @Published var nearbyStores: [StoreInfo] = []
  @Published var storeDetails: [String: StoreDetail] = [:]
  @Published var selectedCategory: String? = nil
  @Published var filterPicchelin: Bool = false
  @Published var filterMyPick: Bool = false
  @Published var nearbySort: NearbySort = .distance

  // 인기 맛집 카테고리 필터링 연산 프로퍼티
  var filteredPopularStores: [StoreInfo] {
    if let selected = selectedCategory {
      return popularStores.filter { $0.category == selected }
    } else {
      return popularStores
    }
  }

  // 주변 가게 정렬/필터 연산 프로퍼티
  var filteredAndSortedNearbyStores: [StoreInfo] {
    var result = nearbyStores
    if filterPicchelin && filterMyPick {
      result = result.filter { $0.isPicchelin && $0.isPick }
    } else if filterPicchelin {
      result = result.filter { $0.isPicchelin }
    } else if filterMyPick {
      result = result.filter { $0.isPick }
    }
    switch nearbySort {
    case .orders:
      return result.sorted { $0.totalOrderCount > $1.totalOrderCount }
    case .reviews:
      return result.sorted { $0.totalReviewCount > $1.totalReviewCount }
    case .distance:
      return result.sorted { $0.geolocation.longitude < $1.geolocation.longitude }
    }
  }

  // 서비스 의존성
  private let networkService: NetworkProtocol

  // 초기화
  init(networkService: NetworkProtocol) {
    self.networkService = networkService
  }

  // MARK: - 액션 디스패처 - 모든 상태 변경은 이 메서드를 통과
  func dispatch(_ action: StoreAction) {
    switch action {
    // 로딩 상태 처리
    case .setLoading(let isLoading):
      self.isLoading = isLoading

    // 오류 처리
    case .setError(let message):
      self.error = message

    // 데이터 액션 처리
    case .setMyPickStores:
      break

    case .setSearchText(let text):
      self.searchText = text

    case .setNextCursor(let cursor):
      self.nextCursor = cursor

    // 가게 좋아요 토글
    case .toggleStoreLike(let storeId):
      // 이제 직접 async 함수로 호출하므로 dispatch에서는 제거
      break
    }
  }

  // MARK: - 공개 메서드

  // 가게 좋아요 토글
  func toggleStoreLike(storeId: String, currentLikeStatus: Bool) async throws {
    let newLikeStatus = !currentLikeStatus
    let _: ResponseDTOs.StoreLike = try await networkService.request(
      endpoint: StoreEndpoint.storeLike(storeId: storeId, likeStatus: newLikeStatus)
    )
    await MainActor.run {
      self.updateStoreLikeStatus(storeId: storeId, isPick: newLikeStatus)
    }
  }

  // 좋아요 상태 동기화
  func updateStoreLikeStatus(storeId: String, isPick: Bool) {
    if let idx = popularStores.firstIndex(where: { $0.id == storeId }) {
      popularStores[idx].isPick = isPick
    }
    if let idx = nearbyStores.firstIndex(where: { $0.id == storeId }) {
      nearbyStores[idx].isPick = isPick
    }
    if var detail = storeDetails[storeId] {
      detail.isPick = isPick
      storeDetails[storeId] = detail
    }
  }

  // 검색어 설정
  func updateSearchText(_ text: String) {
    dispatch(.setSearchText(text: text))
    // 필요 시 검색 로직 구현
    if !text.isEmpty && text.count > 2 {
      Task {
        await searchStores(name: text)
      }
    }
  }

  func fetchPopularSearches() async -> [String] {
    do {
      let response: PopularSearches = try await networkService.request(
        endpoint: StoreEndpoint.popularSearches
      )
      return response.data
    } catch {
      handleError(error: error, defaultMessage: "인기 검색어 로드 실패")
      return []
    }
  }

  // 내 주변 가게 데이터 fetch (상태는 View에서만 소유)
  func fetchNearbyStores(
    latitude: Double, longitude: Double, maxDistance: Double, next: String = "", limit: Int = 5,
    orderBy: String
  ) async -> (stores: [StoreInfo], nextCursor: String) {
    do {
      let response: StoreList = try await networkService.request(
        endpoint: StoreEndpoint.storeList(
          category: nil,
          longitude: longitude,
          latitude: latitude,
          maxDistance: maxDistance,
          next: next.isEmpty ? nil : next,
          limit: limit,
          orderBy: orderBy
        )
      )
      let nextCursor = response.nextCursor
      return (response.data, nextCursor)
    } catch {
      handleError(error: error, defaultMessage: "주변 가게 로드 실패")
      return ([], "0")
    }
  }

  // 가게 검색
  private func searchStores(name: String) async {
    dispatch(.setLoading(isLoading: true))
    do {
      let response: StoreSearch = try await networkService.request(
        endpoint: StoreEndpoint.searchStores(name: name)
      )
      // 검색 결과는 View에서만 사용
    } catch {
      handleError(error: error, defaultMessage: "가게 검색 실패")
    }
    dispatch(.setLoading(isLoading: false))
  }

  // 인기 가게 로드
  func fetchPopularStores(category: String?) async -> [StoreInfo] {
    do {
      let response: PopularStores = try await networkService.request(
        endpoint: StoreEndpoint.popularStores(category: nil)
      )
      return response.data
    } catch {
      handleError(error: error, defaultMessage: "인기 가게 로드 실패")
      return []
    }
  }

  func fetchDetail(storeId: String) async -> StoreDetail {
    do {
      let response: StoreDetail = try await networkService.request(
        endpoint: StoreEndpoint.storeDetail(storeId: storeId)
      )
      return response
    } catch {
      handleError(error: error, defaultMessage: "가게 상세 정보 로드 실패")
      return StoreDetail.empty
    }
  }

  // 에러 처리 공통 메서드
  private func handleError(error: Error, defaultMessage: String) {
    if let networkError = error as? NetworkError {
      dispatch(.setError(message: networkError.localizedDescription ?? defaultMessage))
    } else {
      dispatch(.setError(message: defaultMessage))
    }
    print("\(defaultMessage): \(error.localizedDescription)")
  }
}
