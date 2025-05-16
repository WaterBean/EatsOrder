//
//  ProfileModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/16/25.
//

import Foundation

@MainActor
final class ProfileModel: ObservableObject {

  let service: NetworkProtocol
  
  init(service: NetworkProtocol) {
    self.service = service
  }
  
  func myProfile() async -> ProfileResponse {
    do {
      let a: ProfileResponse = try await service.request(endpoint: UserEndpoint.myProfile)
      return a
    } catch {
      return ProfileResponse(user_id: "", email: "", nick: "", profileImage: "", phoneNum: "")
    }
  }
}
