//
//  AuthMiddleware.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

final class AuthMiddleware: Middleware {
  private let tokenManager: TokenManager
  private let refreshTokenHandler: () async -> Bool
  private let tokenExpiredHandler: () -> Void
  
  init(
    tokenManager: TokenManager,
    refreshTokenHandler: @escaping () async -> Bool,
    tokenExpiredHandler: @escaping () -> Void
  ) {
    self.tokenManager = tokenManager
    self.refreshTokenHandler = refreshTokenHandler
    self.tokenExpiredHandler = tokenExpiredHandler
  }
  
  func prepare(request: inout URLRequest) {
    // 토큰이 있으면 요청 헤더에 추가
    if tokenManager.isLoggedIn {
      print(tokenManager.accessToken)
      request.addValue(tokenManager.accessToken, forHTTPHeaderField: "Authorization")
    }
  }
  
  func process(response: HTTPURLResponse, data: Data) async throws -> Result<Bool, Error> {
    // 419 에러(인증 실패)인 경우 토큰 갱신 시도
    if response.statusCode == 419 {
      // 클로저를 통해 토큰 갱신 요청
      let refreshSuccess = await refreshTokenHandler()
      
      if refreshSuccess {
        return .success(true) // 재시도 필요
      } else {
        // 토큰 갱신 실패 - 토큰 만료 처리
        tokenExpiredHandler()
        return .failure(NetworkError.authenticationFailed(message: "토큰 갱신 실패. 다시 로그인해주세요."))
      }
    } else if response.statusCode == 418 {
      tokenExpiredHandler()
      return .failure(NetworkError.authenticationFailed(message: "세션이 만료되었습니다. 다시 로그인해주세요."))
    }
    
    return .success(false) // 재시도 불필요
  }
}
