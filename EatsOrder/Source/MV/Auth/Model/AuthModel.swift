//
//  AuthModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import UIKit
import EOCore
import KakaoSDKAuth
import KakaoSDKUser

// 인증 관련 모든 액션을 정의하는 열거형
enum AuthAction {
  
  // 오류 상태 액션
  case setError(message: String)
  case clearError
  
  // 세션 상태 액션
  case setSessionState(state: AuthModel.AuthState)
  
  // 토큰 관련 액션
  case saveTokens(accessToken: String, refreshToken: String)
  case clearTokens
  
  // 로그인 상태 액션
  case setLoggedIn(isLoggedIn: Bool)
  case setLoginSuccess(success: Bool)
  case setJoinSuccess(success: Bool)
  
  // 이메일 검증 결과 액션
  case setEmailValidationResult(result: String)
}

// 로그인 타입 enum 정의
enum LoginType: String {
  case email, kakao, apple

  var displayName: String {
    switch self {
    case .email: return "email"
    case .kakao: return "kakao"
    case .apple: return "apple"
    }
  }
}

@MainActor
final class AuthModel: ObservableObject {
  // 세션 상태 열거형
  enum AuthState {
    case initial
    case active
    case refreshing
    case expired
  }

  private let service: NetworkProtocol
  private let tokenManager: TokenManager
  
  // 상태 관리
  @Published private(set) var sessionState: AuthState = .initial
  @Published private(set) var emailValidationResult: String = ""
  @Published private(set) var errorMessage: String = ""
  @Published private(set) var isLoggedIn: Bool = false
  @Published private(set) var loginSuccess: Bool = false
  @Published private(set) var joinSuccess: Bool = false

  // @UserDefault propertyWrapper 활용
  @UserDefault(key: "lastLoginType", defaultValue: "") private var lastLoginTypeRaw: String
  @UserDefault(key: "lastLoginDate", defaultValue: 0.0) private var lastLoginDateRaw: Double

  private func saveLastLoginInfo(type: LoginType) {
    lastLoginTypeRaw = type.rawValue
    lastLoginDateRaw = Date().timeIntervalSince1970
  }

  var lastLoginType: LoginType? {
    LoginType(rawValue: lastLoginTypeRaw)
  }
  var lastLoginDate: Date? {
    lastLoginDateRaw > 0 ? Date(timeIntervalSince1970: lastLoginDateRaw) : nil
  }
  
  // 초기화
  init(service: NetworkProtocol, tokenManager: TokenManager) {
    self.service = service
    self.tokenManager = tokenManager
    
    // 초기 로그인 상태 설정
    self.isLoggedIn = tokenManager.isLoggedIn
    
    // 로그인 상태이지만 토큰이 만료된 경우 체크
    if self.isLoggedIn {
      if tokenManager.isAccessTokenExpired() {
        dispatch(.setSessionState(state: .expired))
      } else {
        dispatch(.setSessionState(state: .active))
      }
    }
    
    // 앱 생명주기 관찰
    setupAppLifecycleObservers()
  }
  
  // 액션 디스패처 - 모든 상태 변경은 이 메서드를 통과
  func dispatch(_ action: AuthAction) {
    switch action {
      // 로딩 상태 처리
      
      // 오류 처리
    case .setError(let message):
      self.errorMessage = message
      
    case .clearError:
      self.errorMessage = ""
      
      // 세션 상태 처리
    case .setSessionState(let state):
      self.sessionState = state
      
      // 토큰 관리
    case .saveTokens(let accessToken, let refreshToken):
      tokenManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
      
    case .clearTokens:
      tokenManager.clearTokens()
      
      // 로그인 상태 관리
    case .setLoggedIn(let isLoggedIn):
      self.isLoggedIn = isLoggedIn
      
    case .setLoginSuccess(let success):
      self.loginSuccess = success
      
    case .setJoinSuccess(let success):
      self.joinSuccess = success
      
      // 이메일 검증 결과
    case .setEmailValidationResult(let result):
      self.emailValidationResult = result
    }
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
  
  // 에러 처리 공통 메서드
  private func handleError(error: Error, defaultMessage: String) {
    if let networkError = error as? NetworkError {
      dispatch(.setError(message: networkError.localizedDescription ?? defaultMessage))
    } else {
      dispatch(.setError(message: defaultMessage + ": " + error.localizedDescription))
    }
    print("\(defaultMessage): \(error.localizedDescription)")
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

  // 토큰 갱신 처리
  func handleTokenRefreshNeeded() async -> Bool {
    print("토큰 갱신 준비")
    // 이미 갱신 중이면 중복 실행 방지
    guard sessionState != .refreshing else {
      print("토큰 갱신이 준비중임")
      return false
    }
    // 상태 업데이트
    dispatch(.setSessionState(state: .refreshing))
    do {
      // 리프레시 토큰으로 새 토큰 요청
      let refreshEndpoint = AuthEndpoint.refresh(refreshToken: tokenManager.refreshToken)
      let response: Token = try await service.rawRequest(endpoint: refreshEndpoint)
      // 새 토큰 저장
      dispatch(.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken))
      dispatch(.setSessionState(state: .active))
      print("토큰 갱신 성공")
      return true
    } catch {
      handleError(error: error, defaultMessage: "토큰 갱신 실패")
      // 갱신 실패 - 세션 만료로 간주
      dispatch(.setSessionState(state: .expired))
      return false
    }
  }
  
  // 세션 만료 처리
  func handleSessionExpiration() {
    // 모든 상태 초기화 (순서 중요)
    dispatch(.clearTokens)
    dispatch(.setLoggedIn(isLoggedIn: false))
    dispatch(.setLoginSuccess(success: false))
    dispatch(.setSessionState(state: .expired))
    dispatch(.setError(message: "세션이 만료되었습니다. 다시 로그인해주세요."))
    
    print("세션 만료 처리 완료")
  }
  
  // 이메일 유효성 검사
  func emailValidation(email: String) async {
    dispatch(.clearError)
    
    do {
      let response: ResponseDTOs.Message = try await service.request(
        endpoint: UserEndpoint.validateEmail(email: email)
      )
      dispatch(.setEmailValidationResult(result: response.message))
    } catch {
      handleError(error: error, defaultMessage: "이메일 유효성 검사 실패")
      dispatch(.setEmailValidationResult(result: errorMessage))
    }
  }
  
  // 로그인
  func login(email: String, password: String, deviceToken: String = "") async {
    // 초기 상태 설정
    dispatch(.setLoginSuccess(success: false))
    
    do {
      let response: Login = try await service.request(
        endpoint: UserEndpoint.login(email: email, password: password, deviceToken: deviceToken)
      )
      
      // 성공 처리 - 순서 중요
      dispatch(.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken))
      dispatch(.setSessionState(state: .active))
      dispatch(.setLoggedIn(isLoggedIn: true))
      dispatch(.setLoginSuccess(success: true))
      
      // 마지막 로그인 정보 저장
      saveLastLoginInfo(type: .email)
      
      print("로그인 성공")
    } catch {
      handleError(error: error, defaultMessage: "로그인에 실패하였습니다")
    }
  }
  
  // 회원가입
  func join(email: String, password: String, nick: String, phoneNum: String = "", deviceToken: String = "") async {
    // 초기 상태 설정
    dispatch(.setJoinSuccess(success: false))
    
    do {
      let response: Join = try await service.rawRequest(
        endpoint: UserEndpoint.join(
          email: email,
          password: password,
          nick: nick,
          phoneNum: phoneNum,
          deviceToken: deviceToken
        )
      )
      
      // 성공 처리 - 순서 중요
      dispatch(.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken))
      dispatch(.setSessionState(state: .active))
      dispatch(.setLoggedIn(isLoggedIn: true))
      dispatch(.setJoinSuccess(success: true))

      // 마지막 로그인 정보 저장
      saveLastLoginInfo(type: .email)
      
      print("회원가입 성공")
    } catch {
      handleError(error: error, defaultMessage: "회원가입 실패")
    }
  }
  
  // 카카오 로그인
  func kakaoLogin(oauthToken: String, deviceToken: String = "") async {
    // 초기 상태 설정
    dispatch(.setLoginSuccess(success: false))
    
    do {
      let response: Login = try await service.request(
        endpoint: UserEndpoint.kakaoLogin(oauthToken: oauthToken, deviceToken: deviceToken)
      )
      
      // 성공 처리
      dispatch(.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken))
      dispatch(.setSessionState(state: .active))
      dispatch(.setLoggedIn(isLoggedIn: true))
      dispatch(.setLoginSuccess(success: true))

      // 마지막 로그인 정보 저장
      saveLastLoginInfo(type: .kakao)
      
      print("카카오 로그인 성공")
    } catch {
      handleError(error: error, defaultMessage: "카카오 로그인 실패")
    }
  }
  
  // 애플 로그인
  func appleLogin(idToken: String, deviceToken: String = "", nick: String? = nil) async {
    // 초기 상태 설정
    dispatch(.setLoginSuccess(success: false))
    
    do {
      let response: Login = try await service.request(
        endpoint: UserEndpoint.appleLogin(idToken: idToken, deviceToken: deviceToken, nick: nick)
      )
      
      // 성공 처리
      dispatch(.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken))
      dispatch(.setSessionState(state: .active))
      dispatch(.setLoggedIn(isLoggedIn: true))
      dispatch(.setLoginSuccess(success: true))
      
      // 마지막 로그인 정보 저장
      saveLastLoginInfo(type: .apple)
      
      print("애플 로그인 성공")
    } catch {
      handleError(error: error, defaultMessage: "애플 로그인 실패")
    }
  }
  
  // 로그아웃
  func logout() {
    // 모든 상태 초기화 (순서 중요)
    dispatch(.clearTokens)
    dispatch(.setLoggedIn(isLoggedIn: false))
    dispatch(.setLoginSuccess(success: false))
    dispatch(.setSessionState(state: .expired))
    dispatch(.clearError)
    
    print("로그아웃 완료")
  }
}
