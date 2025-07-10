//
//  TokenManager.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation
import EOCore

final class TokenManager {
  @UserDefault(key: accessTokenKey, defaultValue: "") var accessToken
  @UserDefault(key: refreshTokenKey, defaultValue: "") var refreshToken
  
  private static let accessTokenKey = "accessToken"
  private static let refreshTokenKey = "refreshToken"
  
  // 토큰 유효성 체크 기능
  var isLoggedIn: Bool {
    return !accessToken.isEmpty && !refreshToken.isEmpty
  }
  
  // JWT 토큰 디코딩으로 만료 시간 확인
  func isAccessTokenExpired() -> Bool {
    guard !accessToken.isEmpty else { return true }
    
    // JWT 파싱 로직
    let parts = accessToken.components(separatedBy: ".")
    guard parts.count == 3 else { return true }
    
    // Base64 디코딩 (패딩 처리)
    let base64 = base64UrlToBase64(parts[1])
    guard let payloadData = Data(base64Encoded: base64) else {
      return true
    }
    
    do {
      // JWT 페이로드 디코딩
      if let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
         let expTimestamp = payload["exp"] as? TimeInterval {
        // 현재 시간과 비교
        let expDate = Date(timeIntervalSince1970: expTimestamp)
        print(expDate, Date())
        return Date() >= expDate
      }
    } catch {
      print("JWT 디코딩 실패: \(error)")
    }
    
    return true // 파싱 실패 시 만료된 것으로 간주
  }
  
  func saveTokens(accessToken: String, refreshToken: String) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
  }

  func clearTokens() {
    accessToken = ""
    refreshToken = ""
  }
  
  private func base64UrlToBase64(_ base64: String) -> String {
    var base64 = base64
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    
    if base64.count % 4 != 0 {
      base64.append(String(repeating: "=", count: 4 - base64.count % 4))
    }
    
    return base64
  }
}
