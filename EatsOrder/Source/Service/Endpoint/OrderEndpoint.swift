//
//  OrderEndpoint.swift
//  EatsOrder
//
//  Created by 한수빈 on 6/9/25
//

import Foundation

enum OrderEndpoint: EndpointProtocol {

  case createOrder(storeId: String, orderMenuList: [RequestDTOs.OrderMenu], totalPrice: Int)
  case fetchOrders
  case updateOrderStatus(orderCode: String, nextStatus: String)

  var baseURL: URL? {
    return URL(string: Environments.baseURL)
  }

  var path: String {
    switch self {
    case .createOrder:
      return "/orders"
    case .fetchOrders:
      return "/orders"
    case .updateOrderStatus(let orderCode, _):
      return "/orders/\(orderCode)"
    }
  }

  var method: NetworkMethod {
    switch self {
    case .createOrder:
      return .post
    case .fetchOrders:
      return .get
    case .updateOrderStatus:
      return .put
    }
  }

  var parameters: [URLQueryItem]? {
    switch self {
    case .createOrder, .updateOrderStatus:
      return nil
    case .fetchOrders:
      return nil
    }
  }

  var headers: [String: String]? {
    return [
      "Content-Type": "application/json",
      "SeSACKey": Environments.apiKey,
    ]
  }

  var body: Encodable? {
    switch self {
    case .createOrder(let storeId, let orderMenuList, let totalPrice):
      return RequestDTOs.OrderCreate(store_id: storeId, order_menu_list: orderMenuList, total_price: totalPrice)
    case .updateOrderStatus(_, let nextStatus):
      return RequestDTOs.OrderStatusUpdate(nextStatus: nextStatus)
    case .fetchOrders:
      return nil
    }
  }
}
