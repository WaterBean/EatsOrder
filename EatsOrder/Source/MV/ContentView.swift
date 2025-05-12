//
//  ContentView.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import SwiftUI

struct ContentView: View {
  @State var isShowSignInScreen = false
  var body: some View {
    
    VStack {
      Text(Environments.apiKey)
      
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
  }
}

#if DEBUG
#Preview {
  ContentView()
}
#endif
