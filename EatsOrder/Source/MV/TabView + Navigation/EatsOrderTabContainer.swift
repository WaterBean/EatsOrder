//
//  EatsOrderTabContainer.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import SwiftUI

private struct IsTabBarHiddenKey: EnvironmentKey {
  static let defaultValue: Binding<Bool> = .constant(false)
}
extension EnvironmentValues {
  var isTabBarHidden: Binding<Bool> {
    get { self[IsTabBarHiddenKey.self] }
    set { self[IsTabBarHiddenKey.self] = newValue }
  }
}

struct EatsOrderTabContainer: View {
  @EnvironmentObject var authModel: AuthModel
  @EnvironmentObject var profileModel: ProfileModel
  @EnvironmentObject var storeModel: StoreModel
  @EnvironmentObject var orderModel: OrderModel
  @State private var isShowSignInScreen = false
  @State private var isTabBarHidden: Bool = false
  @StateObject private var router = Router()
  @Namespace private var animation
  @State private var showCart = false

  var cartCount: Int {
    orderModel.cart?.totalQuantity ?? 0
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: $router.selectedTab) {
        ForEach(EatsOrderTab.allCases, id: \.self) { tab in
          tab.screen
            .tag(tab.rawValue)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .toolbar(.hidden, for: .tabBar)
        .edgesIgnoringSafeArea(.all)
      }
      Group {
        EatsOrderTabView(selectedTab: $router.selectedTab)
        if !showCart {
          TabBarFloatingButton(
            onTap: {
              withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCart = true
              }
            },
            cartCount: cartCount,
            animation: animation
          )
          .padding(.bottom, 38)
          .transition(.scale)

        } else {
          CartFullScreen(
            animation: animation,
            cart: orderModel.cart,
            onUpdateQuantity: { menuId, quantity in
              orderModel.updateMenuQuantity(menuId: menuId, quantity: quantity)
            },
            onRemove: { menuId in
              orderModel.removeMenuFromCart(menuId: menuId)
            },
            onClose: {
              withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCart = false
              }
            },
            onPaymentSuccess: {
              withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCart = false
                router.homePath.removeAll()
                router.selectedTab = .order
              }
            }
          )
          .transition(.identity)

        }
      }
      .offset(y: isTabBarHidden ? 120 : 0)
      .opacity(isTabBarHidden ? 0 : 1)
      .animation(.easeOut(duration: 0.35), value: isTabBarHidden)
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
      case .expired, .initial:
        isShowSignInScreen = true
      default:
        isShowSignInScreen = false
      }
    }
    .environmentObject(router)
    .environment(\.isTabBarHidden, $isTabBarHidden)
  }
}

struct EatsOrderTabView: View {
  @Binding var selectedTab: EatsOrderTab

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
              isSelected: selectedTab == EatsOrderTab.allCases[index]
            ) {
              selectedTab = EatsOrderTab.allCases[index]
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
              isSelected: selectedTab == EatsOrderTab.allCases[index]
            ) {
              selectedTab = EatsOrderTab.allCases[index]
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

struct TabBarHiddenModifier: ViewModifier {
  let hidden: Bool
  @Environment(\.isTabBarHidden) private var isTabBarHidden

  func body(content: Content) -> some View {
    content
      .onAppear { isTabBarHidden.wrappedValue = hidden }
      .onDisappear { isTabBarHidden.wrappedValue = !hidden }
  }
}

extension View {
  func tabBarHidden(_ hidden: Bool = true) -> some View {
    self.modifier(TabBarHiddenModifier(hidden: hidden))
  }
}
