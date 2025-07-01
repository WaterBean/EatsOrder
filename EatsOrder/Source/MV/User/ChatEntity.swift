//
//  ChatEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import Foundation

struct ChatRoom: Entity {
  let roomId: String
  let participants: [ChatParticipant]
  let lastMessage: Chat?
  let updatedAt: String
  let unreadCount: Int

  var id: String { roomId }
}

struct ChatParticipant: Entity {
  let userId: String
  let nick: String
  let profileImage: String?
  var id: String { userId }
}

enum ChatSendState: String, Codable {
  case sending, sent, failed
}

struct Chat: Entity {
  let chatId: String
  let roomId: String
  let content: String
  let createdAt: String
  let sender: ChatParticipant
  let files: [String]?
  var sendState: ChatSendState? = nil
  var id: String { chatId }
}
