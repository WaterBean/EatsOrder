//
//  ChatModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 6/11/25.
//

import Foundation

@MainActor
final class ChatModel: ObservableObject {
  private let socketService = ChatSocketService()
  private let networkService: NetworkService

  @Published var rooms: [ChatRoom] = []
  @Published var isLoadingRooms: Bool = false
  @Published var roomsError: String? = nil

  // 채팅방별 메시지 관리
  @Published var messages: [Chat] = []
  @Published var isPaging: Bool = false
  @Published var hasMore: Bool = true
  private var nextCursor: String? = nil

  init(networkService: NetworkService) {
    self.networkService = networkService
  }

  func createOrFetchRoom(opponentId: String) async throws -> ChatRoom {
    let endpoint = ChatEndpoint.createOrFetchRoom(opponentId: opponentId)
    let response: ResponseDTOs.ChatRoom = try await networkService.request(endpoint: endpoint)
    return response.toEntity()
  }

  func fetchRooms() async {
    isLoadingRooms = true
    roomsError = nil
    do {
      let response: ResponseDTOs.ChatRoomList = try await networkService.request(
        endpoint: ChatEndpoint.fetchRooms)
      rooms = response.data.map { $0.toEntity() }
    } catch {
      roomsError = error.localizedDescription
    }
    isLoadingRooms = false
  }

  func sendMessage(roomId: String, content: String, files: [String]?) async throws -> Chat {
    let endpoint = ChatEndpoint.sendMessage(roomId: roomId, content: content, files: files)
    let response: ResponseDTOs.Chat = try await networkService.request(endpoint: endpoint)
    return response.toEntity()
  }

  func fetchMessages(roomId: String, next: String?) async throws -> [Chat] {
    let endpoint = ChatEndpoint.fetchMessages(roomId: roomId, next: next)
    let response: ResponseDTOs.ChatList = try await networkService.request(endpoint: endpoint)
    return response.data.map { $0.toEntity() }
  }

  // 초기 메시지 동기화
  func loadInitialMessages(roomId: String) async {
    isPaging = true
    do {
      let response = try await fetchMessages(roomId: roomId, next: nil)
      messages = response
      nextCursor = response.last?.createdAt.toString()
      hasMore = response.count == 20
    } catch {
      // 에러 처리 필요시 추가
    }
    isPaging = false
  }

  // 페이징(과거 내역 추가)
  func loadMoreMessages(roomId: String) async {
    guard hasMore, !isPaging else { return }
    isPaging = true
    do {
      let response = try await fetchMessages(roomId: roomId, next: nextCursor)
      messages.insert(contentsOf: response, at: 0)
      nextCursor = response.last?.createdAt.toString()
      hasMore = response.count == 20
    } catch {
      // 에러 처리 필요시 추가
    }
    isPaging = false
  }

  // 메시지 전송 (실패/재전송 포함)
  func sendMessage(roomId: String, content: String) async {
    let tempId = UUID().uuidString
    let myUserId = ""  // TODO: 내 userId로 교체
    let myUser = ChatParticipant(userId: myUserId, nick: "나", profileImage: nil)
    let tempMessage = Chat(
      chatId: tempId, roomId: roomId, content: content, createdAt: Date(),
      sender: myUser, files: nil, sendState: .sending)
    messages.append(tempMessage)
    do {
      let sent = try await sendMessage(roomId: roomId, content: content, files: nil)
      if let idx = messages.firstIndex(where: { $0.chatId == tempId }) {
        messages[idx] = sent
      }
    } catch {
      if let idx = messages.firstIndex(where: { $0.chatId == tempId }) {
        messages[idx].sendState = .failed
      }
    }
  }

  func resendMessage(_ message: Chat) async {
    await sendMessage(roomId: message.roomId, content: message.content)
  }

  func deleteMessage(_ message: Chat) {
    messages.removeAll { $0.chatId == message.chatId }
  }

  // MARK: - 소켓 연결/해제
  func connectSocket(roomId: String, onReceive: @escaping (Chat) -> Void) {
    socketService.connect(roomId: roomId, onReceive: onReceive)
  }

  func disconnectSocket() {
    socketService.disconnect()
  }

  func uploadFiles(roomId: String, files: [String]) async throws {
    let endpoint = ChatEndpoint.uploadFiles(roomId: roomId, files: files)
    let response: ResponseDTOs.ChatFilesUpload = try await networkService.request(
      endpoint: endpoint)

  }
}

// MARK: - DTO → Entity 변환
extension ResponseDTOs.ChatRoom {
  func toEntity() -> ChatRoom {
    ChatRoom(
      roomId: roomId,
      participants: participants.map { $0.toEntity() },
      lastMessage: lastChat?.toEntity(),
      updatedAt: updatedAt.toDate(),
      unreadCount: 0  // 서버 응답에 unreadCount가 있으면 매핑
    )
  }
}

extension ResponseDTOs.ChatParticipant {
  func toEntity() -> ChatParticipant {
    ChatParticipant(
      userId: userId,
      nick: nick,
      profileImage: profileImage
    )
  }
}

extension ResponseDTOs.Chat {
  func toEntity() -> Chat {
    Chat(
      chatId: chatId,
      roomId: roomId,
      content: content,
      createdAt: createdAt.toDate() ?? .now,
      sender: sender.toEntity(),
      files: files
    )
  }
}
