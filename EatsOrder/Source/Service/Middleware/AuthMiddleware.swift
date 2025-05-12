//
//  AuthMiddleware.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

final class AuthMiddleware: Middleware {
  private let tokenManager: TokenManager
  private let networkService: NetworkProtocol
  
  init(tokenManager: TokenManager, networkService: NetworkProtocol) {
    self.tokenManager = tokenManager
    self.networkService = networkService
  }
  
  func prepare(request: inout URLRequest) {
    // 토큰이 있으면 요청 헤더에 추가
    if tokenManager.isLoggedIn {
      request.addValue(tokenManager.accessToken, forHTTPHeaderField: "Authorization")
    }
  }
  
  func process(response: HTTPURLResponse, data: Data) async throws -> (Bool, Error?) {
    // 401 에러(인증 실패)인 경우 토큰 갱신 시도
    if response.statusCode == 401 {
      do {
        // 토큰 갱신 시도
        try await refreshTokens()
        return (true, nil) // 재시도 필요
      } catch {
        // 토큰 갱신 실패 - 로그아웃 필요
        tokenManager.clearTokens()
        return (false, NetworkError.authenticationFailed)
      }
    }
    
    return (false, nil) // 재시도 불필요
  }
  
  private func refreshTokens() async throws {
    // 리프레시 토큰을 사용하여 새 토큰 요청
    let refreshEndpoint = AuthEndpoint.refreshToken
    let response: TokenResponse = try await networkService.rawRequest(endpoint: refreshEndpoint)
    
    // 새 토큰 저장
    tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
  }
}
