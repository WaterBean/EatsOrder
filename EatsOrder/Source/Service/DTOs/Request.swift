//
//  Request.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

enum RequestDTOs {

  struct EmailValidation: Encodable {
    let email: String
  }

  struct Join: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String
    let deviceToken: String
  }

  struct Login: Encodable {
    let email: String
    let password: String
    let deviceToken: String
  }

  struct KakaoLogin: Encodable {
    let oauthToken: String
    let deviceToken: String
  }

  struct AppleLogin: Encodable {
    let idToken: String
    let deviceToken: String
    let nick: String
  }

  struct StoreLike: Encodable {
    let like_status: Bool
  }
  
  struct OrderCreate: Encodable {
    let store_id: String
    let order_menu_list: [OrderMenu]
    let total_price: Int
  }

  struct OrderStatusUpdate: Encodable {
    let nextStatus: String
  }

  // 주문 메뉴 정보
  struct OrderMenu: Encodable {
    let menu_id: String
    let quantity: Int
  }

}
