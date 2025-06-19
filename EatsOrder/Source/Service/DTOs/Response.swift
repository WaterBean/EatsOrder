//
//  Response.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

struct ResponseDTOs {
  // 주문 생성 응답
  struct OrderCreate: Decodable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String
  }

  // 주문 내역 조회 응답
  struct OrderList: Decodable {
    let data: [Order]
  }

  struct Order: Decodable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let review: Review?
    let store: Store
    let orderMenuList: [OrderMenu]
    let paidAt: String?
    let createdAt: String
    let updatedAt: String
  }

  struct Review: Decodable {
    let id: String
    let rating: Int
  }

  struct Store: Decodable {
    let id: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let hashTags: [String]
    let geolocation: Geolocation
    let createdAt: String
    let updatedAt: String
  }

  struct Geolocation: Decodable {
    let longitude: Double
    let latitude: Double
  }

  struct OrderMenu: Decodable {
    let menu: Menu
    let quantity: Int
  }

  struct Menu: Decodable {
    let id: String
    let category: String
    let name: String
    let description: String
    let originInformation: String
    let price: Int
    let tags: [String]
    let menuImageUrl: String
    let createdAt: String
    let updatedAt: String
  }

  struct OrderStatusTimeline: Decodable {
    let status: String
    let completed: Bool
    let changedAt: String?
  }

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
  
  struct ChatRoom: Decodable {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [ChatParticipant]
    let lastChat: Chat?
  }

  struct ChatParticipant: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?
  }

  struct Chat: Decodable {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ChatParticipant
    let files: [String]?
  }

  struct ChatRoomList: Decodable {
    let data: [ChatRoom]
  }

  struct ChatList: Decodable {
    let data: [Chat]
  }

  struct ChatFilesUpload: Decodable {
    let files: [String]
  }

  struct PaymentValidation: Decodable {
    let paymentId: String
    let orderItem: Order
    let createdAt: String
    let updatedAt: String
  }

}

// ISO8601 String -> Date 변환 헬퍼
extension String {
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: self)
  }
}
