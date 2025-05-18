//
//  EatsOrderApp.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import SwiftUI

@main
struct MyApp: App {
  @StateObject private var authModel: AuthModel
  @StateObject private var profileModel: ProfileModel
  
  init() {
    // AppSetup 대신 직접 초기화
    let setup = DependencySetup()
    let (authModel, profileModel) = setup.setupDependencies()
    
    self._authModel = StateObject(wrappedValue: authModel)
    self._profileModel = StateObject(wrappedValue: profileModel)
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(authModel)
        .environmentObject(profileModel)
    }
  }
}

final class DependencySetup {
  @MainActor func setupDependencies() -> (AuthModel, ProfileModel) {
    // 1. 기본 의존성 생성
    let tokenManager = TokenManager()
    let networkService = NetworkService(session: URLSession.shared)
    
    // 2. 모델 생성
    let authModel = AuthModel(service: networkService, tokenManager: tokenManager)
    let profileModel = ProfileModel(service: networkService)
    
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
    
    // 4. 네트워크 서비스에 미들웨어 추가
    networkService.addMiddleware(authMiddleware)
    
    return (authModel, profileModel)
  }
}
