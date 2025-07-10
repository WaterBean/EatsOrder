//
//  StoreEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/02.
//

import Foundation
import EOCore

struct StoreInfo: Entity {
  let storeId: String
  let category: String
  let name: String
  let close: String
  let storeImageUrls: [String]
  let isPicchelin: Bool
  var isPick: Bool
  let pickCount: Int
  let hashTags: [String]
  let totalRating: Double
  let totalOrderCount: Int
  let totalReviewCount: Int
  let geolocation: GeoLocation
  let distance: Double?
  let createdAt: String
  let updatedAt: String

  var id: String { storeId }
}

struct Creator: Entity {
  let userId: String
  let nick: String
  let profileImage: String?

  var id: String { userId }
}


struct StoreDetail: Entity {
  let storeId: String
  let category: String?
  let name: String?
  let description: String?
  let hashTags: [String]
  let open: String?
  let close: String?
  let address: String?
  let estimatedPickupTime: Int
  let parkingGuide: String?
  let storeImageUrls: [String]
  let isPicchelin: Bool
  var isPick: Bool
  let pickCount: Int
  let totalReviewCount: Int
  let totalOrderCount: Int
  let totalRating: Double
  let creator: Creator
  let geolocation: GeoLocation
  let menuList: [MenuItem]
  let createdAt: String
  let updatedAt: String

  var id: String { storeId }
  static var empty: StoreDetail { return StoreDetail(storeId: "", category: "", name: "", description: "", hashTags: [], open: "", close: "", address: "", estimatedPickupTime: 0, parkingGuide: "", storeImageUrls: [], isPicchelin: false, isPick: false, pickCount: 0, totalReviewCount: 0, totalOrderCount: 0, totalRating: 0, creator: Creator(userId: "", nick: "", profileImage: ""), geolocation: GeoLocation(longitude: 0, latitude: 0), menuList: [], createdAt: "", updatedAt: "") }
}

struct MenuItem: Entity {
  let menuId: String
  let storeId: String
  let category: String
  let name: String
  let description: String
  let originInformation: String
  let price: Int
  let isSoldOut: Bool
  let tags: [String]
  let menuImageUrl: String?
  let createdAt: String
  let updatedAt: String

  var id: String { menuId }
}

struct StoreList: Entity {
  let data: [StoreInfo]
  let nextCursor: String

  var id: String { UUID().uuidString }
}

// 가게 좋아요/좋아요 취소
struct StoreLike: Entity {
  let likeStatus: Bool

  var id: String { UUID().uuidString }
}

// 가게 이름 검색
struct StoreSearch: Entity {
  let data: [StoreInfo]
  var id: String { UUID().uuidString }
}

// 실시간 인기 가게 조회 응답 (배열 형태로 반환)
typealias PopularStores = StoreSearch

// 인기 검색어 목록
struct PopularSearches: Entity {
  let data: [String]
  var id: String { UUID().uuidString }
}

// 내가 좋아요한 가게리스트
typealias MyLikedStores = StoreList

struct BannerInfo: Entity {
  let id: String
  let imageUrl: String
  let linkUrl: String
}
