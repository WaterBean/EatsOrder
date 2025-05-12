//
//  Response.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

struct TokenResponse: Decodable {
  let accessToken: String
  let refreshToken: String
}

struct LoginResponse: Decodable {
  let user_id: String
  let email: String
  let nick: String
  let profileImage: String?
  let accessToken: String
  let refreshToken: String
}

struct JoinResponse: Decodable {
  let user_id: String
  let email: String
  let nick: String
  let accessToken: String
  let refreshToken: String
}

struct ProfileResponse: Decodable {
  let user_id: String
  let email: String
  let nick: String
  let profileImage: String?
  let phoneNum: String
}

struct MessageResponse: Decodable {
  let message: String
}

