//
//  StoreEndpoint.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import Foundation

enum StoreEndpoint: EndpointProtocol {

  case storeList(
    category: String?, longitude: Double?, latitude: Double?, maxDistance: Double?, next: String?, limit: Int?, orderBy: String?)
  case storeDetail(storeId: String)
  case storeLike(storeId: String, likeStatus: Bool)
  case searchStores(name: String)
  case popularStores(category: String?)
  case popularSearches
  case myLikedStores(category: String?, next: String?, limit: String?)
  case userReviews(userId: String, category: String?, next: String?, limit: Int?)

  var baseURL: URL? {
    return URL(string: Environments.baseURLV1)
  }

  var path: String {
    switch self {
    case .storeList:
      return "/stores"
    case .storeDetail(let storeId):
      return "/stores/\(storeId)"
    case .storeLike(let storeId, _):
      return "/stores/\(storeId)/like"
    case .searchStores:
      return "/stores/search"
    case .popularStores:
      return "/stores/popular-stores"
    case .popularSearches:
      return "/stores/searches-popular"
    case .myLikedStores:
      return "/stores/likes/me"
    case .userReviews(let userId, _, _, _):
      return "/stores/reviews/users/\(userId)"
    }
  }

  var method: NetworkMethod {
    switch self {
    case .storeList, .storeDetail, .searchStores, .popularStores, .popularSearches, .myLikedStores,
      .userReviews:
      return .get
    case .storeLike:
      return .post
    }
  }

  var parameters: [URLQueryItem]? {
    switch self {
    case .storeList(let category, let longitude, let latitude, let maxDistance, let next, let limit, let orderBy):
      var queryItems: [URLQueryItem] = []

      if let category {
        queryItems.append(URLQueryItem(name: "category", value: category))
      }

      if let longitude {
        queryItems.append(URLQueryItem(name: "longitude", value: String(longitude)))
      }

      if let latitude {
        queryItems.append(URLQueryItem(name: "latitude", value: String(latitude)))
      }

      if let maxDistance {
        queryItems.append(URLQueryItem(name: "maxDistance", value: String(maxDistance)))
      }

      if let next {
        queryItems.append(URLQueryItem(name: "next", value: next))
      }

      if let limit {
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
      }

      if let orderBy {
        queryItems.append(URLQueryItem(name: "order_by", value: orderBy))
      }

      return queryItems.isEmpty ? nil : queryItems

    case .searchStores(let name):
      return [URLQueryItem(name: "name", value: name)]

    case .popularStores(let category):
      guard let category = category else { return nil }
      return [URLQueryItem(name: "category", value: category)]

    case .myLikedStores(let category, let next, let limit):
      var queryItems: [URLQueryItem] = []

      if let category = category {
        queryItems.append(URLQueryItem(name: "category", value: category))
      }

      if let next = next {
        queryItems.append(URLQueryItem(name: "next", value: next))
      }

      if let limit = limit {
        queryItems.append(URLQueryItem(name: "limit", value: limit))
      }

      return queryItems.isEmpty ? nil : queryItems

    case .userReviews(_, let category, let next, let limit):
      var queryItems: [URLQueryItem] = []
      if let category = category {
        queryItems.append(URLQueryItem(name: "category", value: category))
      }
      if let next = next {
        queryItems.append(URLQueryItem(name: "next", value: next))
      }
      if let limit = limit {
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
      }
      return queryItems.isEmpty ? nil : queryItems

    case .storeDetail, .storeLike, .popularSearches:
      return nil
    }
  }

  var headers: [String: String]? {
    switch self {
    default:
      return [
        "Content-Type": "application/json",
        "SeSACKey": Environments.apiKey,
      ]
    }
  }

  var body: Encodable? {
    switch self {
    case .storeLike(_, let likeStatus):
      return RequestDTOs.StoreLike(like_status: likeStatus)

    case .storeList, .storeDetail, .searchStores, .popularStores, .popularSearches, .myLikedStores, .userReviews:
      return nil
    }
  }
}
