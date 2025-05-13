//
//  AuthModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import Foundation

@MainActor
final class AuthModel: ObservableObject {
  
  private let service: NetworkProtocol
  private let tokenManager: TokenManager
  
  // 상태 관리
  @Published var emailValidationResult: String = ""
  @Published var isLoading: Bool = false
  @Published var errorMessage: String = ""
  @Published var isLoggedIn: Bool = false
  @Published var loginSuccess: Bool = false
  @Published var joinSuccess: Bool = false
  
  // 초기화
  init(service: NetworkService, tokenManager: TokenManager) {
    self.service = service
    self.tokenManager = tokenManager
    self.isLoggedIn = tokenManager.isLoggedIn
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
      
      isLoggedIn = true
      loginSuccess = true
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
      print(response)
      tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
      
      isLoggedIn = true
      joinSuccess = true
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
    isLoggedIn = false
    loginSuccess = false
  }
  
}
