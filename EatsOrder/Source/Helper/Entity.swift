//
//  Entity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/02.
//

import Foundation

typealias Entity = Codable & Identifiable & Equatable


// 여러 응답에서 공통으로 사용되는 가게 정보 모델
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

  var id: String {
    storeId
  }
}

// 위치 정보 모델
struct GeoLocation: Entity {
  let longitude: Double
  let latitude: Double

  var id: String {
    "\(longitude)-\(latitude)"
  }
}

// 유저 정보 모델
struct Creator: Entity {
  let userId: String
  let nick: String
  let profileImage: String?

  var id: String {
    userId
  }
}

// MARK: - 응답 DTO

// 2. 가게 상세 정보 조회 응답
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
  let isPick: Bool
  let pickCount: Int
  let totalReviewCount: Int
  let totalOrderCount: Int
  let totalRating: Double
  let creator: Creator
  let geolocation: GeoLocation
  let menuList: [MenuItem]
  let createdAt: String
  let updatedAt: String

  var id: String {
    storeId
  }
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

  var id: String {
    menuId
  }
}

