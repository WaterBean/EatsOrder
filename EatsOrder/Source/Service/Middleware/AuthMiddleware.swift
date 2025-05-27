//
//  AuthMiddleware.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

actor TokenRefreshState {
  private var isRefreshing = false
  private var refreshTask: Task<Bool, Never>?

  func refreshToken(handler: @escaping () async -> Bool) async -> Bool {
    // 이미 갱신 중인 경우 기존 작업의 결과를 기다림
    if let existingTask = refreshTask {
      return await existingTask.value
    }

    // 새로운 갱신 작업 생성
    let task = Task<Bool, Never> {
      isRefreshing = true
      defer {
        isRefreshing = false
        refreshTask = nil
      }
      return await handler()
    }

    refreshTask = task
    return await task.value
  }
}

final class AuthMiddleware: Middleware {
  private let tokenManager: TokenManager
  private let refreshTokenHandler: () async -> Bool
  private let tokenExpiredHandler: () -> Void
  private let refreshState: TokenRefreshState

  init(
    tokenManager: TokenManager,
    refreshTokenHandler: @escaping () async -> Bool,
    tokenExpiredHandler: @escaping () -> Void
  ) {
    self.tokenManager = tokenManager
    self.refreshTokenHandler = refreshTokenHandler
    self.tokenExpiredHandler = tokenExpiredHandler
    self.refreshState = TokenRefreshState()
  }

  func prepare(request: inout URLRequest) {
    if tokenManager.isLoggedIn {
      request.addValue(tokenManager.accessToken, forHTTPHeaderField: "Authorization")
    }
  }

  func process(response: HTTPURLResponse, data: Data) async throws -> Result<Bool, Error> {
    if response.statusCode == 419 {
      // Actor를 통해 토큰 갱신 처리
      let refreshSuccess = await refreshState.refreshToken(handler: refreshTokenHandler)

      if refreshSuccess {
        return .success(true)  // 재시도 필요
      } else {
        tokenExpiredHandler()
        return .failure(NetworkError.authenticationFailed(message: "토큰 갱신 실패. 다시 로그인해주세요."))
      }
    } else if response.statusCode == 418 {
      tokenExpiredHandler()
      return .failure(NetworkError.authenticationFailed(message: "세션이 만료되었습니다. 다시 로그인해주세요."))
    }

    return .success(false)
  }
}
