//  ChattingRoomScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/12.
//

import SwiftUI

struct ChattingRoomScreen: View {
  @EnvironmentObject var chatModel: ChatModel
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
          ForEach(chatModel.messages) { message in
            ChatMessageCell(
              message: message,
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
    .navigationTitle(room?.participants.first?.nick ?? "채팅방")
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
  var onResend: (() -> Void)?
  var onDelete: (() -> Void)?

  var body: some View {
    HStack {
      if message.sender.userId == "" {  // TODO: 내 userId로 비교
        Spacer()
        VStack(alignment: .trailing) {
          Text(message.content)
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
          if message.sendState == .failed {
            HStack(spacing: 8) {
              Button(action: { onResend?() }) {
                Image(systemName: "arrow.clockwise.circle.fill")
              }
              Button(action: { onDelete?() }) {
                Image(systemName: "trash")
              }
            }
            .foregroundColor(.red)
          } else if message.sendState == .sending {
            ProgressView().scaleEffect(0.5)
          }
        }
      } else {
        VStack(alignment: .leading) {
          Text(message.content)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        Spacer()
      }
    }
    .id(message.id)
  }
}
