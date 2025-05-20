//
//  EatsOrderTabContainer.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import SwiftUI

struct EatsOrderTabContainer: View {
  @EnvironmentObject var authModel: AuthModel
  @State var isShowSignInScreen = false
  @State private var selectedTabIndex = 0
  
  var body: some View {
    
    ZStack(alignment: .bottom) {
      TabView(selection: $selectedTabIndex) {
        ForEach(EatsOrderTab.allCases, id: \.self) { tab in
          tab.view
            .tag(tab.rawValue)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .toolbar(.hidden, for: .tabBar)
        .edgesIgnoringSafeArea(.all)
      }
      // 커스텀 탭바
      EatsOrderTabView(selectedTabIndex: $selectedTabIndex)
      // 플로팅 버튼
      TabBarFloatingButton()
        .offset(y: -45)
    }
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
      switch state {
      case .expired :
        isShowSignInScreen = true
      default:
        isShowSignInScreen = false
      }
    }
  }
}

struct EatsOrderTabView: View {
  @Binding var selectedTabIndex: Int
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      
      ZStack {
        // 배경 이미지
        Image("tabbar-background")
          .resizable()
          .aspectRatio(4.875, contentMode: .fit)
          .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -2)
        
        // 탭 버튼들
        HStack {
          ForEach(0..<2) { index in
            Spacer()
            TabButton(
              icon: EatsOrderTab.allCases[index].iconName,
              isSelected: selectedTabIndex == index
            ) {
              selectedTabIndex = index
            }
            Spacer()
          }
          
          // 가운데 공간
          Spacer()
          Spacer()
          
          ForEach(2..<4) { index in
            Spacer()
            TabButton(
              icon: EatsOrderTab.allCases[index].iconName,
              isSelected: selectedTabIndex == index
            ) {
              selectedTabIndex = index
            }
            Spacer()
          }
        }
        .padding(.top, 10)
      }
      .frame(maxWidth: .infinity)
      .edgesIgnoringSafeArea([.horizontal, .bottom])
      
      // 홈 인디케이터 공간
      Color(UIColor.systemBackground)
        .frame(height: 20)
        .edgesIgnoringSafeArea(.bottom)
    }
    .frame(maxWidth: .infinity)
    .edgesIgnoringSafeArea(.bottom)
    .backgroundStyle(Color.clear)
  }
}

struct TabButton: View {
  let icon: String
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Image(icon)
        .foregroundColor(isSelected ? .blackSprout : .gray)
    }
  }
}


