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

  @Published var profile = Profile(userId: "", email: "", nick: "", profileImage: nil, phoneNum: "")
  
  init(service: NetworkProtocol) {
    self.service = service
  }

  func fetchMyProfile() async -> Profile {
    do {
      let profile: Profile = try await service.request(endpoint: UserEndpoint.myProfile)
      self.profile = profile
      return profile
    } catch {
      let empty = Profile(userId: "", email: "", nick: "", profileImage: nil, phoneNum: "")
      self.profile = empty
      return empty
    }
  }
}
