//
//  ProfileScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import SwiftUI

struct ProfileScreen: View {
  @EnvironmentObject var authModel: AuthModel
  @EnvironmentObject var profileModel: ProfileModel
  @EnvironmentObject var chatModel: ChatModel

  var body: some View {
    VStack(spacing: 0) {
      ProfileView(profile: profileModel.profile)
        .padding(.top, 24)
        .padding(.bottom, 24)
      Divider()
      ChattingRoomListView()
    }
    .onAppear {
      Task {
        await profileModel.fetchMyProfile()
      }
    }
  }
}

struct ProfileView: View {
  let profile: Profile?
  var body: some View {
    if let profile = profile {
      VStack(spacing: 12) {
        if let url = profile.profileImage, !url.isEmpty {
          AsyncImage(url: URL(string: url)) { image in
            image.resizable()
          } placeholder: {
            Color.gray.opacity(0.2)
          }
          .frame(width: 80, height: 80)
          .clipShape(Circle())
        } else {
          Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 80, height: 80)
        }
        Text(profile.nick)
          .font(.title2.bold())
        Text(profile.email)
          .font(.subheadline)
          .foregroundColor(.secondary)
        Text(profile.phoneNum ?? "")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity)
    } else {
      VStack(spacing: 12) {
        ProgressView()
          .frame(width: 80, height: 80)
        Text("프로필 정보를 불러오는 중...")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity)
    }
  }
}
