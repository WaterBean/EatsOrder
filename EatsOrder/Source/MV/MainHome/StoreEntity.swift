//
//  StoreEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/05/27.
//

import Foundation

struct BannerInfo: Identifiable {
  let id: String
  let imageUrl: String
  let title: String
  let badgeText: String
}

struct Store: Identifiable {
  let storeId: String
  let category: String
  let name: String
  let close: String
  let storeImageurls: [String]
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