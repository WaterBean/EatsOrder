//
//  EatsOrderApp.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Combine
import KakaoSDKAuth
import KakaoSDKCommon
import SwiftUI
//import iamport_ios

@main
struct EatsOrderApp: App {
  @StateObject private var authModel: AuthModel
  @StateObject private var profileModel: ProfileModel
  @StateObject private var storeModel: StoreModel
  @StateObject private var locationModel: LocationModel
  @StateObject private var orderModel: OrderModel
  @StateObject private var chatModel: ChatModel
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  
  init() {
    // KakaoSDK 초기화
    KakaoSDK.initSDK(appKey: Environments.kakaoNativeAppKey)

    // 의존성 설정
    let setup = DependencySetup()
    let (authModel, profileModel, storeModel, locationModel, orderModel, chatModel) = setup.setupDependencies()

    // StateObject 초기화
    self._authModel = StateObject(wrappedValue: authModel)
    self._profileModel = StateObject(wrappedValue: profileModel)
    self._storeModel = StateObject(wrappedValue: storeModel)
    self._locationModel = StateObject(wrappedValue: locationModel)
    self._orderModel = StateObject(wrappedValue: orderModel)
    self._chatModel = StateObject(wrappedValue: chatModel)
  }

  var body: some Scene {
    WindowGroup {
      EatsOrderTabContainer()
        .onOpenURL(perform: handleOpenURL)
        .environmentObject(authModel)
        .environmentObject(profileModel)
        .environmentObject(storeModel)
        .environmentObject(locationModel)
        .environmentObject(orderModel)
        .environmentObject(chatModel)
    }
  }

  private func handleOpenURL(_ url: URL) {
    if AuthApi.isKakaoTalkLoginUrl(url) {
      _ = AuthController.handleOpenUrl(url: url)
      return
    } else {
//      Iamport.shared.receivedURL(url)
      return
    }
  }

}

// MARK: - 의존성 설정
final class DependencySetup {
  @MainActor func setupDependencies() -> (AuthModel, ProfileModel, StoreModel, LocationModel, OrderModel, ChatModel) {
    // 1. 기본 의존성 생성
    let tokenManager = TokenManager()
    let networkService = NetworkService(session: URLSession.shared)
    let locationModel = LocationModel()

    // 2. 모델 생성
    let authModel = AuthModel(service: networkService, tokenManager: tokenManager)
    let profileModel = ProfileModel(service: networkService)
    let storeModel = StoreModel(networkService: networkService)
    let orderModel = OrderModel(networkService: networkService)
    let chatModel = ChatModel(networkService: networkService)

    // 3. 미들웨어 생성 및 설정 (안전한 weak 참조 사용)
    let authMiddleware = AuthMiddleware(
      tokenManager: tokenManager,
      refreshTokenHandler: { [weak authModel] in
        print("refresh 토큰핸들러 진입 직전")
        return await authModel?.handleTokenRefreshNeeded() ?? false
      },
      tokenExpiredHandler: { [weak authModel] in
        Task { @MainActor in
          authModel?.handleSessionExpiration()
        }
      }
    )
    let loggingMiddleware = LoggingMiddleware()

    // 4. 네트워크 서비스에 미들웨어 추가
    networkService.addMiddleware(authMiddleware)
    networkService.addMiddleware(loggingMiddleware)

    return (authModel, profileModel, storeModel, locationModel, orderModel, chatModel)
  }
}
