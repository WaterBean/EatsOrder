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
  case serverError(statusCode: Int)
  case authenticationFailed
  case authRetryNeeded
  case maxRetriesExceeded
}
