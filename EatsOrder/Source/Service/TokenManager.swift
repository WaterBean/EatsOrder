//
//  TokenManager.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

final class TokenManager {
  @UserDefault(key: accessTokenKey, defaultValue: "") var accessToken
  @UserDefault(key: refreshTokenKey, defaultValue: "") var refreshToken
  
  private static let accessTokenKey = "accessToken"
  private static let refreshTokenKey = "refreshToken"
  
  // 토큰 유효성 체크 기능 추가
  var isLoggedIn: Bool {
    return !accessToken.isEmpty && !refreshToken.isEmpty
  }
  
  // JWT 토큰 디코딩으로 만료 시간 확인
  func isAccessTokenExpired() -> Bool {
    
    // TODO: - JWT 디코딩 로직 (간단한 구현)
    // 이후 JWT 토큰을 디코딩하고 exp 필드를 확인해야 함
    guard !accessToken.isEmpty else { return true }
    
    return false
  }
  
  func saveTokens(accessToken: String, refreshToken: String) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
  }
  
  func clearTokens() {
    accessToken = ""
    refreshToken = ""
  }
  
  func logout() {
    clearTokens()
  }
  
}
