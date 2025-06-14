//
//  ChatEndpoint.swift
//  EatsOrder
//
//  Created by 한수빈 on 6/11/25.
//

import Foundation

enum ChatEndpoint: EndpointProtocol {
  case createOrFetchRoom(opponentId: String)
  case fetchRooms
  case sendMessage(roomId: String, content: String, files: [String]?)
  case fetchMessages(roomId: String, next: String?)
  case uploadFiles(roomId: String, files: [String])

  var baseURL: URL? {
    return URL(string: Environments.baseURLV1)
  }

  var path: String {
    switch self {
    case .createOrFetchRoom:
      return "/chats"
    case .fetchRooms:
      return "/chats"
    case .sendMessage(let roomId, _, _):
      return "/chats/\(roomId)"
    case .fetchMessages(let roomId, _):
      return "/chats/\(roomId)"
    case .uploadFiles(let roomId, _):
      return "/chats/\(roomId)/files"
    }
  }

  var method: NetworkMethod {
    switch self {
    case .createOrFetchRoom:
      return .post
    case .fetchRooms:
      return .get
    case .sendMessage:
      return .post
    case .fetchMessages:
      return .get
    case .uploadFiles:
      return .post
    }
  }

  var parameters: [URLQueryItem]? {
    switch self {
    case .fetchMessages(_, let next):
      if let next = next {
        return [URLQueryItem(name: "next", value: next)]
      }
      return nil
    default:
      return nil
    }
  }

  var headers: [String: String]? {
    switch self {
    case .uploadFiles:
      [
        "Content-Type": "multipart/form-data",
        "SeSACKey": Environments.apiKey,
      ]
    default:
      [
        "Content-Type": "application/json",
        "SeSACKey": Environments.apiKey,
      ]
    }
  }

  var body: Encodable? {
    switch self {
    case .createOrFetchRoom(let opponentId):
      return RequestDTOs.ChatRoomCreate(opponent_id: opponentId)
    case .sendMessage(_, let content, let files):
      return RequestDTOs.ChatSend(content: content, files: files)
    case .uploadFiles(_, let files):
      return RequestDTOs.ChatFilesUpload(files: files)
    default:
      return nil
    }
  }
}
