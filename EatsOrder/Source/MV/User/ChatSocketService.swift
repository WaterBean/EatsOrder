//  ChatSocketService.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/12.
//

import Foundation
import SocketIO

@MainActor
final class ChatSocketService {
  private var manager: SocketManager?
  private var socket: SocketIOClient?
  private var roomId: String?
  private var onReceive: ((Chat) -> Void)?
  private var isConnected: Bool = false

  func connect(roomId: String, onReceive: @escaping (Chat) -> Void) {
    disconnect()
    self.roomId = roomId
    self.onReceive = onReceive
    let urlString = "\(Environments.baseURL)/chats-\(roomId)"
    guard let url = URL(string: urlString) else { return }
    manager = SocketManager(socketURL: url, config: [
      .log(false),
      .compress,
      .extraHeaders([
        "SeSACKey": Environments.apiKey,
        "Authorization": TokenManager().accessToken
      ])
    ])
    socket = manager?.defaultSocket
    addHandlers()
    socket?.connect()
  }

  func disconnect() {
    socket?.disconnect()
    manager = nil
    socket = nil
    roomId = nil
    onReceive = nil
    isConnected = false
  }

  private func addHandlers() {
    socket?.on(clientEvent: .connect) { [weak self] data, ack in
      print("[Socket] Connected", data)
      self?.isConnected = true
    }
    socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
      print("[Socket] Disconnected", data)
      self?.isConnected = false
    }
    socket?.on("chat") { [weak self] data, ack in
      guard let self = self, let dict = data.first as? [String: Any],
            let chat = ChatSocketService.parseChat(dict: dict) else { return }
      self.onReceive?(chat)
    }
    socket?.on(clientEvent: .error) { data, ack in
      print("[Socket] Error", data)
    }
  }

  // 서버에서 내려주는 채팅 json을 Chat 엔티티로 변환
  private static func parseChat(dict: [String: Any]) -> Chat? {
    guard let chatId = dict["chat_id"] as? String,
          let roomId = dict["room_id"] as? String,
          let content = dict["content"] as? String,
          let createdAt = dict["createdAt"] as? String,
          let senderDict = dict["sender"] as? [String: Any],
          let senderId = senderDict["user_id"] as? String,
          let nick = senderDict["nick"] as? String,
          let profileImage = senderDict["profileImage"] as? String? else { return nil }
    let sender = ChatParticipant(userId: senderId, nick: nick, profileImage: profileImage)
    let files = dict["files"] as? [String]
    return Chat(chatId: chatId, roomId: roomId, content: content, createdAt: createdAt, sender: sender, files: files)
  }
}
