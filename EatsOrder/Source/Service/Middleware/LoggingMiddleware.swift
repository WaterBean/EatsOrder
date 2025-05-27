//
//  LoggingMiddleware.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation
import os.log

final class LoggingMiddleware: Middleware {
  private let logger = Logger(subsystem: "com.eatsorder", category: "network")
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()

  func prepare(request: inout URLRequest) {
    // 요청 ID 생성
    let requestId = "\(request.url?.absoluteString ?? "unknown")_\(Date().timeIntervalSince1970)"

    // 요청 ID를 헤더에 추가
    request.setValue(requestId, forHTTPHeaderField: "X-Request-ID")

    // 로깅을 위한 요청 정보 복사
    let url = request.url?.absoluteString ?? "unknown"
    let method = request.httpMethod ?? "unknown"
    let headers = request.allHTTPHeaderFields
    let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? "none"
    let timestamp = dateFormatter.string(from: Date())

    // 로깅
    logger.debug(
      """
      [\(timestamp)] 📤 REQUEST [\(requestId)]
      URL: \(url)
      Method: \(method)
      Headers: \(headers?.description ?? "none")
      Body: \(body)
      """)
  }

  func process(response: HTTPURLResponse, data: Data) async throws -> Result<Bool, Error> {
    let requestId = response.allHeaderFields["X-Request-ID"] as? String ?? "unknown"
    let timestamp = dateFormatter.string(from: Date())

    logger.debug(
      """
      [\(timestamp)] 📥 RESPONSE [\(requestId)]
      Status: \(response.statusCode)
      Headers: \(response.allHeaderFields)
      Body: \(String(data: data, encoding: .utf8) ?? "none")
      """)

    return .success(false)
  }
}
