//
//  UserEndpoint.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

enum UserEndpoint: EndpointProtocol {
  
  // 유저 관련
  case validateEmail(email: String)
  case join(email: String, password: String, nick: String, phoneNum: String, deviceToken: String)
  case login(email: String, password: String, deviceToken: String)
  case kakaoLogin(oauthToken: String, deviceToken: String)
  case appleLogin(idToken: String, deviceToken: String, nick: String?)
  case myProfile
  
  // MARK: - EndpointProtocol 구현
  
  var baseURL: URL? {
    return URL(string: Environments.baseURL)
  }
  
  var path: String {
    switch self {
      // 유저 관련
    case .validateEmail:
      return "/users/validation/email"
    case .join:
      return "/users/join"
    case .login:
      return "/users/login"
    case .kakaoLogin:
      return "/users/login/kakao"
    case .appleLogin:
      return "/users/login/apple"
    case .myProfile:
      return "/users/me/profile"
    }
  }
  
  var method: NetworkMethod {
    switch self {
    case .myProfile:
      return .get
    case .validateEmail, .join, .login, .kakaoLogin, .appleLogin:
      return .post
    }
  }
  
  var parameters: [URLQueryItem]? {
    return nil
  }
  
  var headers: [String: String]? {
    switch self {
    default:
      return [
        "Content-Type": "application/json",
        "SeSACKey": Environments.apiKey
      ]
    }
  }
  
  var body: Encodable? {
    switch self {
    case .validateEmail(let email):
      return EmailValidationRequest(email: email)
      
    case .join(let email, let password, let nick, let phoneNum, let deviceToken):
      return JoinRequest(
        email: email,
        password: password,
        nick: nick,
        phoneNum: phoneNum,
        deviceToken: deviceToken
      )
      
    case .login(let email, let password, let deviceToken):
      return LoginRequest(
        email: email,
        password: password,
        deviceToken: deviceToken
      )
      
    case .kakaoLogin(let oauthToken, let deviceToken):
      return KakaoLoginRequest(
        oauthToken: oauthToken,
        deviceToken: deviceToken
      )
      
    case .appleLogin(let idToken, let deviceToken, let nick):
      return AppleLoginRequest(
        idToken: idToken,
        deviceToken: deviceToken,
        nick: nick
      )
      
    case .myProfile:
      return nil
    }
  }
  
}
