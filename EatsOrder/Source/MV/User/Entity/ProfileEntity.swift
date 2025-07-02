//
//  ProfileEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import Foundation

struct Profile: Entity {
  let userId: String
  let email: String
  let nick: String
  let profileImage: String?
  let phoneNum: String?

  var id: String {
    userId
  }
}
