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
  
  func myProfile() async -> Profile {
    do {
      let profile: Profile = try await service.request(endpoint: UserEndpoint.myProfile)
      return profile
    } catch {
      return Profile(userId: "", email: "", nick: "", profileImage: "", phoneNum: "")
    }
  }
}
