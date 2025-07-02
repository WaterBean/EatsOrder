//
//  AuthEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/02.
//

import Foundation

struct Token: Entity {
  let accessToken: String
  let refreshToken: String

  var id: String {
    accessToken
  }
}

struct Login: Entity {
  let userId: String
  let email: String
  let nick: String
  let profileImage: String?
  let accessToken: String
  let refreshToken: String

  var id: String {
    userId
  }
}

struct Join: Entity {
  let userId: String
  let email: String
  let nick: String
  let accessToken: String
  let refreshToken: String

  var id: String {
    userId
  }
}


