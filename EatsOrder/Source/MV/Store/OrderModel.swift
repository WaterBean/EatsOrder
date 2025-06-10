//
//  OrderModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/09.
//

import Foundation

@MainActor
final class OrderModel: ObservableObject {
  
  private let networkService: NetworkService

  // 장바구니: 한 번에 하나의 가게만 주문 가능
  @Published var cart: Cart? = nil
  // 주문 내역
  @Published var orderList: [Order] = []

  init(networkService: NetworkService) {
    self.networkService = networkService
  }


  // 메뉴 추가
  func addMenuToCart(storeId: String, storeName: String, menu: CartMenuItem) {
    if cart == nil || cart?.id != storeId {
      // 다른 가게 장바구니면 새로 생성
      cart = Cart(id: storeId, storeName: storeName, items: [menu])
    } else {
      // 이미 담긴 메뉴면 수량 증가, 아니면 추가
      if let idx = cart?.items.firstIndex(where: { $0.id == menu.id }) {
        cart?.items[idx].quantity += menu.quantity
      } else {
        cart?.items.append(menu)
      }
    }
  }

  // 메뉴 수량 변경
  func updateMenuQuantity(menuId: String, quantity: Int) {
    guard var cart = cart else { return }
    if let idx = cart.items.firstIndex(where: { $0.id == menuId }) {
      cart.items[idx].quantity = quantity
      self.cart = cart
    }
  }

  // 메뉴 삭제
  func removeMenuFromCart(menuId: String) {
    guard var cart = cart else { return }
    cart.items.removeAll { $0.id == menuId }
    if cart.items.isEmpty {
      self.cart = nil
    } else {
      self.cart = cart
    }
  }

  // 장바구니 비우기
  func clearCart() {
    cart = nil
  }

  // 주문 생성, 주문 내역 조회 등은 네트워크 연동 후 추가 예정
}
