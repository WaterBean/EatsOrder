//
//  AuthEndpoint.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import Foundation

enum AuthEndpoint: EndpointProtocol {
  
  case refresh(refreshToken: String)
  
  var baseURL: URL? {
    return URL(string: Environments.baseURL)
  }
  
  var path: String {
    switch self {
    case .refresh:
      return "/auth/refresh"
    }
  }
  
  var method: NetworkMethod {
    switch self {
    case .refresh:
        .get
    }
  }
  
  var parameters: [URLQueryItem]? {
    switch self {
    case .refresh:
      nil
    }
  }
  
  var headers: [String: String]? {
    switch self {
    case .refresh(let refreshToken):
    return [
      "Content-Type": "application/json",
      "SeSACKey": Environments.apiKey,
      "RefreshToken": refreshToken,
      "Authorization": TokenManager().accessToken
    ]
    }
  }
  
  var body: Encodable? {
    switch self {
    case .refresh: nil
    }
  }
  
}
