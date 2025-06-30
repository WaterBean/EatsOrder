//
//  OrderModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/09.
//

import Foundation
import iamport_ios

@MainActor
final class OrderModel: ObservableObject {
  
  private let networkService: NetworkService

  // 장바구니: 한 번에 하나의 가게만 주문 가능
  @Published var cart: Cart? = nil
  // 주문 내역
  @Published var orderList: [Order] = []
  @Published var pendingPayment: PaymentInfo? = nil
  @Published var paymentResult: PaymentResult? = nil

  init(networkService: NetworkService) {
    self.networkService = networkService
  }

  struct PaymentInfo: Identifiable, Equatable {
    let orderCode: String
    let totalPrice: Int
    let storeName: String
    var id: String { orderCode }
  }

  struct PaymentResult: Identifiable, Equatable {
    let success: Bool
    let message: String
    var id: String { message + String(success) }
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

  // 주문 생성 및 order_code 발급
  func createOrder() async throws -> String? {
    guard let cart else { return nil }
    let orderMenuList = cart.items.map { item in
      RequestDTOs.OrderMenu(menu_id: item.id, quantity: item.quantity)
    }
    let endpoint = OrderEndpoint.createOrder(
      storeId: cart.id,
      orderMenuList: orderMenuList,
      totalPrice: cart.totalPrice
    )
    let response: ResponseDTOs.OrderCreate = try await networkService.request(endpoint: endpoint)
    return response.orderCode
  }

  // 결제 영수증 검증
  func validatePayment(impUid: String) async -> Bool {
    let endpoint = OrderEndpoint.validatePayment(impUid: impUid)
    do {
      let _: ResponseDTOs.PaymentValidation = try await networkService.request(endpoint: endpoint)
      return true
    } catch {
      print("결제 검증 실패: \(error)")
      return false
    }
  }

  // 주문 생성 및 결제 정보 준비
  func preparePayment() async {
    guard let cart = cart, !cart.items.isEmpty else { return }
    let totalPrice = cart.totalPrice
    let storeName = cart.storeName
    do {
      if let orderCode = try await createOrder(), !orderCode.isEmpty, totalPrice > 0,
        !storeName.isEmpty
      {
        pendingPayment = PaymentInfo(
          orderCode: orderCode, totalPrice: totalPrice, storeName: storeName)
      }
    } catch {
      paymentResult = PaymentResult(success: false, message: "주문 생성 실패: \(error)")
    }
  }

  // 결제 영수증 검증 및 결과 처리
  func handlePaymentCallback(response: IamportResponse) async {
    guard let impUid = response.imp_uid else {
      paymentResult = PaymentResult(success: false, message: "결제 실패(imp_uid 없음)")
      pendingPayment = nil
      return
    }
    let isValid = await validatePayment(impUid: impUid)
    paymentResult = PaymentResult(success: isValid, message: isValid ? "결제 성공!" : "결제 검증 실패")
    if isValid { clearCart() }
    pendingPayment = nil
  }

  // 주문 내역 조회 (네트워크 연동)
  func fetchOrderList() async {
    do {
      let endpoint = OrderEndpoint.fetchOrders
      let response: ResponseDTOs.OrderList = try await networkService.request(endpoint: endpoint)
      let orders = response.data.map { $0.toEntity() }
        .sorted { ($0.paidAt) > ($1.paidAt) }
      await MainActor.run {
        self.orderList = orders
      }
    } catch {
      print("주문 내역 조회 실패: \(error)")
      await MainActor.run {
        self.orderList = []
      }
    }
  }
}

// MARK: - DTO → Entity 변환
private extension ResponseDTOs.Order {
  func toEntity() -> Order {
    Order(
      id: orderId,
      orderCode: orderCode,
      store: store.toEntity(),
      items: orderMenuList.map { $0.toEntity() },
      totalPrice: totalPrice,
      status: OrderStatus(rawValue: currentOrderStatus) ?? .fail,
      createdAt: createdAt.toDate() ?? Date(),
      updatedAt: updatedAt.toDate() ?? Date(),
      paidAt: paidAt.toDate() ?? Date(),
      review: review?.toEntity() ?? Review.empty(),
      statusTimeline: orderStatusTimeline.map { $0.toEntity() }
    )
  }
}
private extension ResponseDTOs.Menu {
  func toEntity() -> CartMenuItem {
    CartMenuItem(id: id, name: name, price: price, quantity: 0, isSoldOut: false)
  }
}

private extension ResponseDTOs.Store {
  func toEntity() -> StoreInfo {
    StoreInfo(
      storeId: id,
      category: category,
      name: name,
      close: close,
      storeImageUrls: storeImageUrls,
      isPicchelin: false,  // 서버 응답에 따라 매핑 필요
      isPick: false,  // 서버 응답에 따라 매핑 필요
      pickCount: 0,  // 서버 응답에 따라 매핑 필요
      hashTags: hashTags,
      totalRating: 0,  // 서버 응답에 따라 매핑 필요
      totalOrderCount: 0,  // 서버 응답에 따라 매핑 필요
      totalReviewCount: 0,  // 서버 응답에 따라 매핑 필요
      geolocation: GeoLocation(longitude: geolocation.longitude, latitude: geolocation.latitude),
      distance: nil,  // 서버 응답에 따라 매핑 필요
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

private extension ResponseDTOs.OrderMenu {
  func toEntity() -> CartMenuItem {
    CartMenuItem(
      id: menu.id,
      name: menu.name,
      price: menu.price,
      quantity: quantity,
      isSoldOut: false
    )
  }
}

private extension ResponseDTOs.Review {
  func toEntity() -> Review {
    Review(id: id, rating: rating)
  }
}

private extension ResponseDTOs.OrderStatusTimeline {
  func toEntity() -> StatusTimeline {
    StatusTimeline(
      status: OrderStatus(rawValue: status) ?? .fail,
      isCompleted: completed,
      changedAt: changedAt?.toDate()
    )
  }
}
