//
//  NetworkProtocol.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

protocol URLSessionProtocol {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol { }

protocol NetworkProtocol {
  var session: URLSessionProtocol { get }
  func request<T: Decodable>(endpoint: EndpointProtocol) async throws -> T
  func rawRequest<T: Decodable>(endpoint: EndpointProtocol) async throws -> T
  func addMiddleware(_ middleware: Middleware)
}

protocol Middleware {
  func prepare(request: inout URLRequest)
  func process(response: HTTPURLResponse, data: Data) async throws -> (Bool, Error?) // (재시도 필요 여부, 에러)
}

protocol EndpointProtocol {
  var baseURL: URL? { get }
  var path: String { get }
  var method: NetworkMethod { get }
  var parameters: [URLQueryItem]? { get }
  var headers: [String: String]? { get }
  var body: Encodable? { get }
  var requiresAuthentication: Bool { get }
  
}

enum NetworkMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
}
