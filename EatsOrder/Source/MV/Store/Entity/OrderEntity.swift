//
//  OrderEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/09.
//

import Foundation
import EOCore

// 주문 메뉴 항목
struct CartMenuItem: Entity {
  let id: String  // menu_id
  let name: String
  let price: Int
  var quantity: Int
  let isSoldOut: Bool
  // 옵션 등 추가 가능
}

// 장바구니(가게 단위)
struct Cart: Entity {
  let id: String  // store_id
  let storeName: String
  var items: [CartMenuItem]
  var totalPrice: Int {
    items.reduce(0) { $0 + $1.price * $1.quantity }
  }
  var totalQuantity: Int {
    items.reduce(0) { $0 + $1.quantity }
  }
}

// 주문 상태(앱 내부용)
enum OrderStatus: String, Codable, CaseIterable, Equatable {
  case pendingApproval = "PENDING_APPROVAL"  // 승인대기
  case approved = "APPROVED"  // 주문승인
  case inProgress = "IN_PROGRESS"  // 조리 중
  case readyForPickup = "READY_FOR_PICKUP"  // 픽업대기
  case pickedUp = "PICKED_UP"  // 픽업완료
  case done = "DONE"
  case cancel = "CANCEL"
  case fail = "FAIL"

  var displayName: String {
    switch self {
    case .pendingApproval: return "승인대기"
    case .approved: return "주문승인"
    case .inProgress: return "조리 중"
    case .readyForPickup: return "픽업대기"
    case .pickedUp: return "픽업완료"
    case .done: return "완료"
    case .cancel: return "취소"
    case .fail: return "실패"
    }
  }
}

// 주문 엔티티(주문 내역)
struct Order: Entity {
  let id: String  // order_id
  let orderCode: String
  let store: StoreInfo
  let items: [CartMenuItem]
  let totalPrice: Int
  let status: OrderStatus
  let createdAt: Date
  let updatedAt: Date
  let paidAt: Date
  let review: Review
  let statusTimeline: [StatusTimeline]

  // 진행중 주문 여부
  var isActive: Bool {
    switch status {
    case .pendingApproval, .approved, .inProgress, .readyForPickup:
      return true
    case .pickedUp, .done, .cancel, .fail:
      return false
    }
  }

  // 리뷰 작성 가능 여부
  var canWriteReview: Bool {
    true
  }
  // 기타 필요한 필드(예: 리뷰, 타임라인 등) 추가 가능
}

struct Review: Entity {
  let id: String
  let rating: Int
  static func empty() -> Review {
    Review(id: "", rating: 0)
  }
}

struct StatusTimeline: Entity {
  let status: OrderStatus
  let isCompleted: Bool
  let changedAt: Date?
  var id: String { status.rawValue }
}

struct PaymentRequest: Entity {
  let pg: String
  let merchant_uid: String
  let amount: Int
  let pay_method: String
  let name: String
  let buyer_name: String
  let app_scheme: String
  var id: String { merchant_uid }
}
