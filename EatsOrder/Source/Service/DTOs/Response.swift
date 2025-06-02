//
//  Response.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

struct TokenResponse: Decodable {
  let accessToken: String
  let refreshToken: String
}

struct LoginResponse: Decodable {
  let user_id: String
  let email: String
  let nick: String
  let profileImage: String?
  let accessToken: String
  let refreshToken: String
}

struct JoinResponse: Decodable {
  let user_id: String
  let email: String
  let nick: String
  let accessToken: String
  let refreshToken: String
}

struct ProfileResponse: Decodable {
  let user_id: String
  let email: String
  let nick: String
  let profileImage: String?
  let phoneNum: String
}

struct MessageResponse: Decodable {
  let message: String
}

// 여러 응답에서 공통으로 사용되는 가게 정보 모델
struct StoreInfo: Decodable {
  let store_id: String
  let category: String
  let name: String
  let close: String
  let store_image_urls: [String]
  let is_picchelin: Bool
  var is_pick: Bool
  let pick_count: Int
  let hashTags: [String]
  let total_rating: Double
  let total_order_count: Int
  let total_review_count: Int
  let geolocation: GeoLocation
  let distance: Double?
  let createdAt: String
  let updatedAt: String

  func toEntity() -> Store {
    return Store(
      storeId: store_id,
      category: category,
      name: name,
      close: close,
      storeImageurls: store_image_urls,
      isPicchelin: is_picchelin,
      isPick: is_pick,
      pickCount: pick_count,
      hashTags: hashTags,
      totalRating: total_rating,
      totalOrderCount: total_order_count,
      totalReviewCount: total_review_count,
      geolocation: geolocation,
      distance: distance,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

// 위치 정보 모델
struct GeoLocation: Decodable {
  let longitude: Double
  let latitude: Double
}

// 유저 정보 모델
struct Creator: Decodable {
  let user_id: String
  let nick: String
  let profileImage: String?
}

// MARK: - 응답 DTO

// 1. 위치 기반 주변 가게 목록 조회 응답
struct StoreListResponse<T: Decodable>: Decodable {
  let data: [T]
  let next_cursor: String
}

// 2. 가게 상세 정보 조회 응답
struct StoreDetailResponse: Decodable {
  let store_id: String
  let category: String?
  let name: String?
  let description: String?
  let hashTags: [String]
  let open: String?
  let close: String?
  let address: String?
  let estimated_pickup_time: Int
  let parking_guide: String?
  let store_image_urls: [String]
  let is_picchelin: Bool
  let is_pick: Bool
  let pick_count: Int
  let total_review_count: Int
  let total_order_count: Int
  let total_rating: Double
  let creator: Creator
  let geolocation: GeoLocation
  let menu_list: [MenuItem]
  let createdAt: String
  let updatedAt: String

  func toEntity() -> StoreDetail {
    return StoreDetail(
      id: store_id,
      name: name ?? "",
      imageUrls: store_image_urls,
      isPicchelin: is_picchelin,
      isPick: is_pick,
      pickCount: pick_count,
      rating: total_rating,
      reviewCount: total_review_count,
      orderCount: total_order_count,
      address: address ?? "",
      openTime: open ?? "",
      closeTime: close ?? "",
      parking: parking_guide ?? "",
      estimatedTime: "\(estimated_pickup_time)분",
      distance: nil,
      menus: menu_list.map { $0.toEntity() }
    )
  }
}

struct MenuItem: Decodable {
  let menu_id: String
  let store_id: String
  let category: String
  let name: String
  let description: String
  let origin_information: String
  let price: Int
  let is_sold_out: Bool
  let tags: [String]
  let menu_image_url: String?
  let createdAt: String
  let updatedAt: String

  func toEntity() -> StoreDetail.Menu {
    let isPopular = tags.contains {
      $0.localizedCaseInsensitiveContains("인기") || $0.localizedCaseInsensitiveContains("popular")
    }
    return StoreDetail.Menu(
      id: menu_id,
      storeId: store_id,
      category: category,
      name: name,
      description: description,
      originInformation: origin_information,
      price: price,
      isSoldOut: is_sold_out,
      tags: tags,
      imageUrl: menu_image_url,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPopular: isPopular
    )
  }
}

// 3. 가게 좋아요/좋아요 취소 응답
struct StoreLikeResponse: Decodable {
  let like_status: Bool
}

// 4. 가게 이름 검색 응답 (StoreListResponse와 구조가 유사하지만 next_cursor가 없음)
struct StoreSearchResponse: Decodable {
  let data: [StoreInfo]
}

// 5. 실시간 인기 가게 조회 응답 (배열 형태로 반환)
typealias PopularStoresResponse = StoreSearchResponse

// 6. 인기 검색어 목록 조회 응답
struct PopularSearchesResponse: Decodable {
  let data: [String]
}

// 7. 내가 좋아요한 가게 조회 응답 (StoreListResponse와 동일한 구조)
typealias MyLikedStoresResponse = StoreListResponse

// ISO8601 String -> Date 변환 헬퍼
extension String {
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: self)
  }
}
