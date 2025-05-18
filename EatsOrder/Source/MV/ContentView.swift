//
//  ContentView.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var authModel: AuthModel
  @EnvironmentObject var profileModel: ProfileModel
  @State var isShowSignInScreen = false
  @State var profile = ProfileResponse(user_id: "", email: "", nick: "", profileImage: "", phoneNum: "")
  
  var body: some View {
    
    VStack {
      Text(Environments.apiKey)
      Text(profile.nick)
      Button {
        Task {
          profile = await profileModel.myProfile()
        }
      } label: {
        Text("프로필 정보 요청")
      }
      Button {
        isShowSignInScreen.toggle()
      } label: {
        Text("로그인하기")
      }

    }
    .padding()
    .fullScreenCover(isPresented: $isShowSignInScreen) {
      SignInScreen()
    }
    .alert("세션 만료", isPresented: $authModel.showSessionExpiredAlert) {
      Button("로그인") {
        isShowSignInScreen = true
      }
    } message: {
      Text("세션이 만료되었습니다. 다시 로그인해주세요.")
    }
    .onReceive(authModel.$sessionState) { state in
      if case .expired = state {
        // 세션 만료 시 로그인 화면 표시 여부 결정
        // (이미 alert에서 처리하므로 여기서는 추가 작업 없음)
      }
    }
  }
}

#if DEBUG
#Preview {
//  ContentView()
//    .environmentObject(AppSetup().createAuthModel())
}
#endif
