//
//  Response.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

struct ResponseDTOs {
  struct Message: Decodable {
    let message: String
  }
  // 1. 위치 기반 주변 가게 목록 조회 응답
struct StoreList: Decodable {
  let data: [StoreInfo]
  let nextCursor: String

}

// 3. 가게 좋아요/좋아요 취소 응답
struct StoreLike: Decodable {
  let likeStatus: Bool

}

// 4. 가게 이름 검색 응답 (StoreListResponse와 구조가 유사하지만 next_cursor가 없음)
struct StoreSearch: Decodable {
  let data: [StoreInfo]
}

// 5. 실시간 인기 가게 조회 응답 (배열 형태로 반환)
typealias PopularStores = StoreSearch

// 6. 인기 검색어 목록 조회 응답
struct PopularSearches: Decodable {
  let data: [String]
}

// 7. 내가 좋아요한 가게 조회 응답 (StoreListResponse와 동일한 구조)
typealias MyLikedStores = StoreList

struct BannerInfo: Decodable {
  let id: String
  let imageUrl: String
  let linkUrl: String
}

}

// ISO8601 String -> Date 변환 헬퍼
extension String {
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: self)
  }
}
