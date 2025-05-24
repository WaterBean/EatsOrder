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
  case setStoreList(stores: [StoreInfo])
  case setPopularStores(stores: [StoreInfo])
  case setBanners(banners: [BannerInfo])
  case setLocation(location: String)
  case setSearchText(text: String)
  case setCategory(category: String?)
  case setNextCursor(cursor: String)
  
  // 상태 변경 액션
  case toggleStoreLike(storeId: String)
}

// MARK: - 스토어 모델
@MainActor
final class StoreModel: ObservableObject {
  // 상태 및 데이터
  @Published private(set) var storeList: [StoreInfo] = []
  @Published private(set) var category: String? = nil
  @Published private(set) var popularStores: [StoreInfo] = []
  @Published private(set) var location: String = "문래역, 영등포구"
  @Published private(set) var searchText: String = ""
  @Published private(set) var currentPage: Int = 0
  @Published private(set) var nextCursor: String = ""
  @Published private(set) var banners: [BannerInfo] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var error: String? = nil
  
  // 서비스 의존성
  private let networkService: NetworkProtocol
  private(set) var locationManager: LocationManager
  
  // 초기화
  init(networkService: NetworkProtocol, locationManager: LocationManager) {
    self.networkService = networkService
    self.locationManager = locationManager
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
    case .setStoreList(let stores):
      self.storeList = stores
      
    case .setPopularStores(let stores):
      self.popularStores = stores
      
    case .setBanners(let banners):
      self.banners = banners
      
    case .setLocation(let location):
      self.location = location
      
    case .setSearchText(let text):
      self.searchText = text
      
    case .setCategory(let category):
      self.category = category
      
    case .setNextCursor(let cursor):
      self.nextCursor = cursor
      
      // 가게 좋아요 토글
    case .toggleStoreLike(let storeId):
      if let index = storeList.firstIndex(where: { $0.store_id == storeId }) {
        var updatedStore = storeList[index]
        updatedStore.is_pick.toggle()
        
        // 좋아요 카운트 업데이트
        //                if updatedStore.is_pick {
        //                    updatedStore.pick_count += 1
        //                } else if updatedStore.pick_count > 0 {
        //                    updatedStore.pick_count -= 1
        //                }
        
        // 해당 인덱스의 가게만 업데이트
        var updatedStores = storeList
        updatedStores[index] = updatedStore
        self.storeList = updatedStores
        
        // API 호출은 별도 함수에서 처리
        Task {
          await toggleStoreLikeAPI(storeId: storeId, isLiked: updatedStore.is_pick)
        }
      }
    }
  }
  
  // MARK: - 공개 메서드
  
  // 초기 데이터 로드
  func loadInitialData(latitude: Double, longitude: Double) async {
    dispatch(.setLoading(isLoading: true))
    dispatch(.setError(message: nil))
    
    // 병렬로 여러 API 호출
    async let storesTask = loadNearbyStores(latitude: latitude, longitude: longitude)
    async let popularTask = loadPopularStores()
    async let bannersTask = loadBanners()
    
    // 모든 작업이 완료될 때까지 대기
    _ = await [storesTask, popularTask, bannersTask]
    
    dispatch(.setLoading(isLoading: false))
  }
  
  // 위치 정보 업데이트
  func updateLocation() async {
    do {
      let locationData = try await locationManager.requestLocation()
      
      // 주소와 위경도 업데이트
      dispatch(.setLocation(location: locationData.address ?? "위치 불명"))
      
      // 새 위치로 가게 정보 다시 로드
      if let coordinates = locationManager.getCurrentCoordinates() {
        await loadNearbyStores(latitude: coordinates.latitude, longitude: coordinates.longitude)
      }
    } catch {
      handleError(error: error, defaultMessage: "위치 정보를 가져오는데 실패했습니다")
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
  
  // 카테고리 필터링
  func filterByCategory(_ category: String?) async {
    dispatch(.setCategory(category: category))
    dispatch(.setLoading(isLoading: true))
    
    do {
      // 카테고리와 위치 정보로 API 호출
      if let coordinates = locationManager.getCurrentCoordinates() {
        let response: StoreListResponse = try await networkService.request(
          endpoint: StoreEndpoint.storeList(
            category: category,
            longitude: Float(coordinates.longitude),
            latitude: Float(coordinates.latitude),
            next: nil,
            limit: 10,
            orderBy: "distance"
          )
        )
        
        dispatch(.setStoreList(stores: response.data))
        dispatch(.setNextCursor(cursor: response.next_cursor))
      }
    } catch {
      handleError(error: error, defaultMessage: "카테고리 필터링 실패")
    }
    
    dispatch(.setLoading(isLoading: false))
  }
  
  // 더 많은 가게 로드 (페이지네이션)
  func loadMoreStores() async {
    // 로딩 중이거나 더 이상 데이터가 없으면 중단
    guard !isLoading, !nextCursor.isEmpty, nextCursor != "0" else { return }
    
    dispatch(.setLoading(isLoading: true))
    
    do {
      if let coordinates = locationManager.getCurrentCoordinates() {
        let response: StoreListResponse = try await networkService.request(
          endpoint: StoreEndpoint.storeList(
            category: category,
            longitude: Float(coordinates.longitude),
            latitude: Float(coordinates.latitude),
            next: nextCursor,
            limit: 10,
            orderBy: "distance"
          )
        )
        
        // 기존 리스트에 새 데이터 추가
        let updatedList = storeList + response.data
        dispatch(.setStoreList(stores: updatedList))
        dispatch(.setNextCursor(cursor: response.next_cursor))
      }
    } catch {
      handleError(error: error, defaultMessage: "추가 가게 로드 실패")
    }
    
    dispatch(.setLoading(isLoading: false))
  }
  
  // MARK: - 내부 메서드
  
  // 주변 가게 로드
  private func loadNearbyStores(latitude: Double, longitude: Double) async {
    do {
      let response: StoreListResponse = try await networkService.request(
        endpoint: StoreEndpoint.storeList(
          category: category,
          longitude: Float(longitude),
          latitude: Float(latitude),
          next: nil,
          limit: 10,
          orderBy: "distance"
        )
      )
      
      dispatch(.setStoreList(stores: response.data))
      dispatch(.setNextCursor(cursor: response.next_cursor))
    } catch {
      handleError(error: error, defaultMessage: "주변 가게 로드 실패")
    }
  }
  
  // 인기 가게 로드
  private func loadPopularStores() async {
    do {
      let response: PopularStoresResponse = try await networkService.request(
        endpoint: StoreEndpoint.popularStores(category: category)
      )
      
      dispatch(.setPopularStores(stores: response))
    } catch {
      handleError(error: error, defaultMessage: "인기 가게 로드 실패")
    }
  }
  
  // 배너 정보 로드
  private func loadBanners() async {
    // 실제 API가 없는 것으로 가정하고 샘플 데이터 사용
    let sampleBanners = [
      BannerInfo(id: "1", imageUrl: "banner1", title: "피자부터 콤피까지\n직업하면 0원", badgeText: "ONLY")
    ]
    
    dispatch(.setBanners(banners: sampleBanners))
  }
  
  // 가게 검색
  private func searchStores(name: String) async {
    dispatch(.setLoading(isLoading: true))
    
    do {
      let response: StoreSearchResponse = try await networkService.request(
        endpoint: StoreEndpoint.searchStores(name: name)
      )
      
      dispatch(.setStoreList(stores: response.data))
    } catch {
      handleError(error: error, defaultMessage: "가게 검색 실패")
    }
    
    dispatch(.setLoading(isLoading: false))
  }
  
  // 좋아요 API 호출
  private func toggleStoreLikeAPI(storeId: String, isLiked: Bool) async {
    do {
      let _: StoreLikeResponse = try await networkService.request(
        endpoint: StoreEndpoint.storeLike(storeId: storeId, likeStatus: isLiked)
      )
      // 성공 시 특별한 처리 필요 없음 (이미 UI는 즉시 반영됨)
    } catch {
      // API 실패 시 UI 롤백
      handleError(error: error, defaultMessage: "좋아요 처리 실패")
      
      // UI 롤백 - 다시 원래 상태로 변경
      if let index = storeList.firstIndex(where: { $0.store_id == storeId }) {
        var updatedStore = storeList[index]
        updatedStore.is_pick.toggle()
        
        //                // 좋아요 카운트 롤백
        //                if updatedStore.is_pick {
        //                    updatedStore.pick_count += 1
        //                } else if updatedStore.pick_count > 0 {
        //                    updatedStore.pick_count -= 1
        //                }
        
        var updatedStores = storeList
        updatedStores[index] = updatedStore
        dispatch(.setStoreList(stores: updatedStores))
      }
    }
  }
  
  // 에러 처리 공통 메서드
  private func handleError(error: Error, defaultMessage: String) {
    if let networkError = error as? NetworkError {
      dispatch(.setError(message: networkError.serverMessage ?? defaultMessage))
    } else {
      dispatch(.setError(message: defaultMessage))
    }
    print("\(defaultMessage): \(error.localizedDescription)")
  }
}

struct BannerInfo: Identifiable {
  let id: String
  let imageUrl: String
  let title: String
  let badgeText: String
}

