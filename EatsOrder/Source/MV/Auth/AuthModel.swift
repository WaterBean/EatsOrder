//
//  AuthModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import UIKit

@MainActor
final class AuthModel: ObservableObject {
  // 세션 상태 열거형
  enum SessionState {
    case active
    case refreshing
    case expired
  }
  
  private let service: NetworkProtocol
  private let tokenManager: TokenManager
  
  // 상태 관리
  @Published var sessionState: SessionState = .active
  @Published var emailValidationResult: String = ""
  @Published var isLoading: Bool = false
  @Published var errorMessage: String = ""
  @Published var isLoggedIn: Bool = false
  @Published var loginSuccess: Bool = false
  @Published var joinSuccess: Bool = false
  @Published var showSessionExpiredAlert: Bool = false
  
  // 초기화
  init(service: NetworkProtocol, tokenManager: TokenManager) {
    self.service = service
    self.tokenManager = tokenManager
    
    // 초기 로그인 상태 설정
    self.isLoggedIn = tokenManager.isLoggedIn
    
    // 로그인 상태이지만 토큰이 만료된 경우 체크
    if self.isLoggedIn && tokenManager.isAccessTokenExpired() {
      self.sessionState = .expired
    }
    
    // 앱 생명주기 관찰
    setupAppLifecycleObservers()
  }
  
  // 앱 생명주기 관찰자 설정
  private func setupAppLifecycleObservers() {
    #if os(iOS)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    #endif
  }
  
  @objc private func appWillEnterForeground() {
    // 앱이 포그라운드로 돌아올 때 세션 확인
    checkSessionValidity()
  }
  
  // 세션 유효성 확인
  func checkSessionValidity() {
    // 현재 로그인되어 있고, 토큰이 만료된 경우
    if isLoggedIn && tokenManager.isAccessTokenExpired() {
      // 토큰 갱신 시도
      Task {
        let refreshSuccess = await handleTokenRefreshNeeded()
        if !refreshSuccess {
          // 갱신 실패 시 세션 만료 처리
          handleSessionExpiration()
        }
      }
    }
  }
  
  // 토큰 갱신 처리 (AuthMiddleware에서 호출)
  func handleTokenRefreshNeeded() async -> Bool {
    print("토큰 갱신 준비")
    // 이미 갱신 중이면 중복 실행 방지
    guard sessionState != .refreshing else {
      // 이미 진행 중인 갱신 작업의 결과를 기다림
      print("토큰 갱신이 준비중임")
      return false
    }
    
    // 상태 업데이트
    sessionState = .refreshing
    isLoading = true
    
    do {
      // 리프레시 토큰으로 새 토큰 요청
      let refreshEndpoint = AuthEndpoint.refresh(refreshToken: tokenManager.refreshToken)
      
      // rawRequest 사용 (미들웨어를 거치지 않음)
      let response: TokenResponse = try await service.rawRequest(endpoint: refreshEndpoint)
      
      // 새 토큰 저장
      tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
      
      // 상태 업데이트
      sessionState = .active
      isLoading = false
      
      print("토큰 갱신 성공")
      return true
    } catch {
      print("토큰 갱신 실패: \(error.localizedDescription)")
      
      // 갱신 실패 - 세션 만료로 간주
      sessionState = .expired
      isLoading = false
      return false
    }
  }
  
  // 세션 만료 처리 (AuthMiddleware에서 호출)
  func handleSessionExpiration() {
    // 토큰 제거
    tokenManager.clearTokens()
    
    // 상태 업데이트
    isLoggedIn = false
    loginSuccess = false
    sessionState = .expired
    
    // UI 알림 트리거
    errorMessage = "세션이 만료되었습니다. 다시 로그인해주세요."
    showSessionExpiredAlert = true
    
    print("세션 만료 처리 완료")
  }
  
  // 이메일 유효성 검사
  func emailValidation(email: String) async {
    isLoading = true
    errorMessage = ""
    
    do {
      let response: MessageResponse = try await service.request(
        endpoint: UserEndpoint.validateEmail(email: email)
      )
      emailValidationResult = response.message
    } catch {
      print("이메일 유효성 검사 실패:", error.localizedDescription)
      emailValidationResult = "이메일 확인 실패"
      errorMessage = error.localizedDescription
    }
    
    isLoading = false
  }
  
  // 로그인
  func login(email: String, password: String, deviceToken: String = "") async {
    isLoading = true
    errorMessage = ""
    loginSuccess = false
    
    do {
      let response: LoginResponse = try await service.request(
        endpoint: UserEndpoint.login(email: email, password: password, deviceToken: deviceToken)
      )
      
      tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
      
      // 세션 상태도 함께 업데이트
      sessionState = .active
      isLoggedIn = true
      loginSuccess = true
      
      print("로그인 성공")
    } catch {
      errorMessage = "로그인 실패: \(error.localizedDescription)"
      
      print("로그인 실패:", error.localizedDescription)
    }
    
    isLoading = false
  }
  
  // 회원가입
  func join(email: String, password: String, nick: String, phoneNum: String = "", deviceToken: String = "") async {
    isLoading = true
    errorMessage = ""
    joinSuccess = false
    
    do {
      let response: JoinResponse = try await service.rawRequest(
        endpoint: UserEndpoint.join(
          email: email,
          password: password,
          nick: nick,
          phoneNum: phoneNum,
          deviceToken: deviceToken
        )
      )
      
      tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
      
      // 상태 업데이트
      sessionState = .active
      isLoggedIn = true
      joinSuccess = true
      
      print("회원가입 성공")
    } catch {
      errorMessage = "회원가입 실패: \(error.localizedDescription)"
      print("회원가입 실패:", error.localizedDescription)
    }
    
    isLoading = false
  }
  
  // 카카오 로그인
  func kakaoLogin(oauthToken: String, deviceToken: String = "") async {
    isLoading = true
    errorMessage = ""
    loginSuccess = false
    
    do {
      let response: LoginResponse = try await service.request(
        endpoint: UserEndpoint.kakaoLogin(oauthToken: oauthToken, deviceToken: deviceToken)
      )
      
      tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
      
      sessionState = .active
      isLoggedIn = true
      loginSuccess = true
    } catch {
      errorMessage = "카카오 로그인 실패: \(error.localizedDescription)"
      print("카카오 로그인 실패:", error.localizedDescription)
    }
    
    isLoading = false
  }
  
  // 애플 로그인
  func appleLogin(idToken: String, deviceToken: String = "", nick: String? = nil) async {
    isLoading = true
    errorMessage = ""
    loginSuccess = false
    
    do {
      let response: LoginResponse = try await service.request(
        endpoint: UserEndpoint.appleLogin(idToken: idToken, deviceToken: deviceToken, nick: nick)
      )
      
      tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
      
      sessionState = .active
      isLoggedIn = true
      loginSuccess = true
    } catch {
      errorMessage = "애플 로그인 실패: \(error.localizedDescription)"
      print("애플 로그인 실패:", error.localizedDescription)
    }
    
    isLoading = false
  }
  
  // 로그아웃
  func logout() {
    tokenManager.clearTokens()
    
    // 상태 업데이트
    isLoggedIn = false
    loginSuccess = false
    sessionState = .expired
    showSessionExpiredAlert = false  // 알림 초기화
  }
}
