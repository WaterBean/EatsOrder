//
//  NetworkService.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

final class NetworkService: NetworkProtocol {
  let session: URLSessionProtocol
  private var middleware: [Middleware] = []
  
  init(session: URLSessionProtocol) {
    self.session = session
  }
  
  // 미들웨어 추가 메서드
  func addMiddleware(_ middleware: Middleware) {
    self.middleware.append(middleware)
  }
  
  // 미들웨어가 적용된 요청 메서드
  func request<T: Decodable>(endpoint: EndpointProtocol) async throws -> T {
    var retryCount = 0
    let maxRetries = 1 // 최대 1회 재시도 (토큰 갱신 후)
    
    while retryCount <= maxRetries {
      do {
        return try await executeRequest(endpoint: endpoint)
      } catch let error as NetworkError {
        if retryCount == maxRetries {
          throw error
        }
        
        // 재시도 여부 결정
        if case .authRetryNeeded = error {
          retryCount += 1
          continue
        }
        
        throw error
      }
    }
    
    throw NetworkError.maxRetriesExceeded
  }
  
  // 미들웨어 없이 생(raw) 요청 수행 (토큰 갱신 등에 사용)
  func rawRequest<T: Decodable>(endpoint: EndpointProtocol) async throws -> T {
    guard let url = configUrl(endpoint: endpoint) else {
      throw NetworkError.invalidUrl
    }
    
    let request = configRequest(url: url, endpoint: endpoint)
    let (data, response) = try await session.data(for: request)
    
    return try processResponse(data: data, response: response)
  }
  
  // 미들웨어가 적용된 실제 요청 수행
  private func executeRequest<T: Decodable>(endpoint: EndpointProtocol) async throws -> T {
    guard let url = configUrl(endpoint: endpoint) else {
      throw NetworkError.invalidUrl
    }
    
    var request = configRequest(url: url, endpoint: endpoint)
    
    // 모든 미들웨어의 prepare 메서드 호출
    for m in middleware {
      m.prepare(request: &request)
    }
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw NetworkError.invalidResponse
    }
    
    // HTTP 상태 코드가 성공 범위(200-304)가 아닌 경우 미들웨어 처리
    if !(200...304).contains(httpResponse.statusCode) {
      // 모든 미들웨어의 process 메서드 호출
      for m in middleware {
        let result = try await m.process(response: httpResponse, data: data)
        switch result {
        case .success(let retry):
          if retry {
            throw NetworkError.authRetryNeeded
          }
        case .failure(let error):
          throw error
        }
      }
      
      // 미들웨어에서 처리되지 않은 에러
      throw NetworkError.serverError(statusCode: httpResponse.statusCode)
    }
    
    do {
      let decoder = JSONDecoder()
      return try decoder.decode(T.self, from: data)
    } catch {
      throw NetworkError.decodingError(error.localizedDescription)
    }
  }
}


extension NetworkService {
  private func configUrl(endpoint: EndpointProtocol) -> URL? {
    guard let url = endpoint.baseURL?.appendingPathComponent(endpoint.path) else {
      return nil
    }
    
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      return nil
    }
    
    components.queryItems = endpoint.parameters
    
    return components.url
  }
  
  private func configRequest(url: URL, endpoint: EndpointProtocol) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    
    if let headers = endpoint.headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }
    
    if let body = endpoint.body {
      request.httpBody = try? JSONEncoder().encode(body)
    }
    
    return request
  }
  
  private func processResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw NetworkError.invalidResponse
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
      throw NetworkError.serverError(statusCode: httpResponse.statusCode)
    }
    
    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw NetworkError.decodingError(error.localizedDescription)
    }
  }
}
