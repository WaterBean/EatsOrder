//
//  NetworkError.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

enum NetworkError: Error {
  case invalidUrl
  case invalidResponse
  case decodingError(String)
  case serverError(statusCode: Int, message: String?)
  case authenticationFailed(message: String?)
  case authRetryNeeded
  case maxRetriesExceeded
  
  // 메시지 접근을 위한 간단한 계산 속성
  var serverMessage: String? {
    switch self {
    case .serverError(_, let message), .authenticationFailed(let message):
      return message
    default:
      return "에러 발생"
    }
  }
  
}
