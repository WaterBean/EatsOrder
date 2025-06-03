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
  
}

extension NetworkError: LocalizedError {
  var localizedDescription: String? {
    switch self {
    case .invalidUrl:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid response"
    case .decodingError(let message):
      return message
    case .serverError(let statusCode, let message):
      return "Server error: \(statusCode) - \(message ?? "Unknown error")"
    case .authenticationFailed(let message):
      return "Authentication failed: \(message ?? "Unknown error")"
    case .authRetryNeeded:
      return "Authentication retry needed"
    case .maxRetriesExceeded:
      return "Max retries exceeded"
    default:
      return "Unknown error"
    }
  }

}