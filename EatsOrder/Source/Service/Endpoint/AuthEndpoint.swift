//
//  AuthEndpoint.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import Foundation

enum AuthEndpoint: EndpointProtocol {
  
  case refreshToken
  
  var baseURL: URL? {
    return URL(string: Environments.baseURL)
  }
  
  var path: String {
    switch self {
    case .refreshToken:
      return "/auth/refresh"
    }
  }
  
  var method: NetworkMethod {
    switch self {
    case .refreshToken:.get
      
    }
  }
  
  var parameters: [URLQueryItem]? {
    switch self {
    case .refreshToken: nil
    }
  }
  
  var headers: [String: String]? {
    return [
      "Content-Type": "application/json",
      "Accept": "application/json",
      "SeSACKey": Environments.apiKey
    ]
  }
  
  var body: Encodable? {
    switch self {
    case .refreshToken: nil
    }
  }
  
  
  var requiresAuthentication: Bool {
    false
  }
}
