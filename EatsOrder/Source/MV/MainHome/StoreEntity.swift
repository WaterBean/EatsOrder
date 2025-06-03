//
//  StoreEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/02.
//

import Foundation

// 1. 위치 기반 주변 가게 목록 조회 응답
struct StoreList: Entity {
  let data: [StoreInfo]
  let nextCursor: String

  var id: String { UUID().uuidString }
}

// 3. 가게 좋아요/좋아요 취소 응답
struct StoreLike: Entity {
  let likeStatus: Bool

  var id: String { UUID().uuidString }
}

// 4. 가게 이름 검색 응답 (StoreListResponse와 구조가 유사하지만 next_cursor가 없음)
struct StoreSearch: Entity {
  let data: [StoreInfo]
  var id: String { UUID().uuidString }
}

// 5. 실시간 인기 가게 조회 응답 (배열 형태로 반환)
typealias PopularStores = StoreSearch

// 6. 인기 검색어 목록 조회 응답
struct PopularSearches: Entity {
  let data: [String]
  var id: String { UUID().uuidString }
}

// 7. 내가 좋아요한 가게 조회 응답 (StoreListResponse와 동일한 구조)
typealias MyLikedStores = StoreList

struct BannerInfo: Entity {
  let id: String
  let imageUrl: String
  let linkUrl: String
}