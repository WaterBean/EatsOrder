//
//  OrderEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/09.
//

import Foundation

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

// 주문 엔티티(주문 내역)
struct Order: Entity {
  let id: String  // order_id
  let orderCode: String
  let storeId: String
  let storeName: String
  let items: [CartMenuItem]
  let totalPrice: Int
  let status: String
  let createdAt: Date
  let updatedAt: Date
  // 기타 필요한 필드(예: 리뷰, 타임라인 등) 추가 가능
}
