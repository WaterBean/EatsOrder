//
//  Request.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

struct EmailValidationRequest: Encodable {
  let email: String
}

struct JoinRequest: Encodable {
  let email: String
  let password: String
  let nick: String
  let phoneNum: String
  let deviceToken: String
}

struct LoginRequest: Encodable {
  let email: String
  let password: String
  let deviceToken: String
}

struct KakaoLoginRequest: Encodable {
  let oauthToken: String
  let deviceToken: String
}

struct AppleLoginRequest: Encodable {
  let idToken: String
  let deviceToken: String
  let nick: String?
}
