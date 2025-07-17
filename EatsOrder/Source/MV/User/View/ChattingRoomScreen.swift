//  ChattingRoomScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/12.
//

import SwiftUI

struct ChattingRoomScreen: View {
  @EnvironmentObject var chatModel: ChatModel
  @EnvironmentObject var profileModel: ProfileModel

  let roomId: String
  var room: ChatRoom? {
    chatModel.rooms.first(where: { $0.roomId == roomId })
  }
  
  @State private var input: String = ""
  @State private var isSending: Bool = false
  @State private var error: String?
  
  var body: some View {
    VStack {
      ScrollViewReader { proxy in
        List {
          ForEach(Array(chatModel.messages.enumerated()), id: \.1.id) { idx, message in
            let currentDate = formattedDate(message.createdAt.ISO8601Format())
            let showDateSeparator: Bool = {
              if idx == 0 { return true }
              let prev = chatModel.messages[idx - 1]
              return formattedDate(prev.createdAt.ISO8601Format()) != currentDate
            }()
            if showDateSeparator {
              DateSeparator(dateString: currentDate)
            }
            ChatMessageCell(
              message: message,
              myId: profileModel.profile.userId,
              onResend: { Task { await chatModel.resendMessage(message) } },
              onDelete: { chatModel.deleteMessage(message) }
            )
            .onAppear {
              // 페이징 트리거: 첫 메시지 도달 시
              if message.id == chatModel.messages.first?.id {
                Task { await chatModel.loadMoreMessages(roomId: roomId) }
              }
            }
          }
          if chatModel.isPaging {
            ProgressView()
              .frame(maxWidth: .infinity)
          }
        }
        .listStyle(.plain)
        .background(Color.white)
        .listRowSeparator(.hidden)
        .onChange(of: chatModel.messages.count) { _ in
          // 새 메시지 도착 시 맨 아래로 스크롤
          if !chatModel.isPaging {
            withAnimation { proxy.scrollTo(chatModel.messages.last?.id, anchor: .bottom) }
          }
        }
      }
      ChatInputBar(input: $input, isSending: isSending) {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        Task {
          await chatModel.sendMessage(roomId: roomId, content: input)
          input = ""
          isSending = false
        }
      }
    }
    .tabBarHidden(true)
    .navigationTitle(chatModel.rooms.first?.participants.first?.nick ?? "채팅방")
    .onAppear {
      Task {
        await chatModel.loadInitialMessages(roomId: roomId)
        chatModel.connectSocket(roomId: roomId) { newMessage in
          // 실시간 메시지 수신 시 UI 갱신
          chatModel.messages.append(newMessage)
        }
      }
    }
    .onDisappear {
      chatModel.disconnectSocket()
    }
  }
}

struct ChatInputBar: View {
  @Binding var input: String
  var isSending: Bool
  var onSend: () -> Void
  
  var body: some View {
    HStack {
      TextField("메시지 입력", text: $input)
        .textFieldStyle(.roundedBorder)
        .frame(minHeight: 36)
      Button {
        onSend()
      } label: {
        Image(systemName: "paperplane.fill")
      }
      .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
    }
    .padding()
  }
}

struct ChatMessageCell: View {
  let message: Chat
  let myId: String?
  var onResend: (() -> Void)?
  var onDelete: (() -> Void)?

  var isMyMessage: Bool { message.sender.userId == myId }

  var body: some View {
    HStack(alignment: .bottom, spacing: 4) {
      if isMyMessage {
        // 내 메시지: 타임스탬프 → Spacer → 말풍선
        Spacer()
        Text(timeString(message.createdAt.ISO8601Format()))
          .font(.caption2)
          .foregroundColor(.gray)
          .padding(.trailing, 2)
        Text(message.content)
          .padding(.vertical, 10)
          .padding(.horizontal, 16)
          .background(
            RoundedRectangle(cornerRadius: 18)
              .fill(Color.blue)
          )
          .foregroundColor(.white)
      } else {
        // 상대 메시지: 말풍선 → Spacer → 타임스탬프
        Text(message.content)
          .padding(.vertical, 10)
          .padding(.horizontal, 16)
          .background(
            RoundedRectangle(cornerRadius: 18)
              .fill(Color.gray.opacity(0.15))
          )
          .foregroundColor(.black)
        Text(timeString(message.createdAt.ISO8601Format()))
          .font(.caption2)
          .foregroundColor(.gray)
          .padding(.leading, 2)
        Spacer()
      }
    }
    .padding(.horizontal, 12)
    .id(message.id)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }
}

struct DateSeparator: View {
  let dateString: String
  var body: some View {
    Text(dateString)
      .font(.caption)
      .foregroundColor(.gray)
      .padding(.vertical, 6)
      .padding(.horizontal, 16)
      .background(Color(.systemGray6))
      .cornerRadius(12)
      .frame(maxWidth: .infinity)
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
      .padding(.vertical, 8)
  }
}

func formattedDate(_ isoString: String) -> String {
  let isoFormatter = ISO8601DateFormatter()
  if let date = isoFormatter.date(from: isoString) {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월 d일"
    return formatter.string(from: date)
  }
  return isoString  // 변환 실패 시 원본 반환(디버깅용)
}

func timeString(_ isoString: String) -> String {
  let isoFormatter = ISO8601DateFormatter()
  if let date = isoFormatter.date(from: isoString) {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }
  return ""
}
