//
//  ChattingRoomListScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 6/11/25.
//

import SwiftUI

struct ChattingRoomListView: View {
  @EnvironmentObject var chatModel: ChatModel
  @Environment(\.navigate) private var navigate

  var body: some View {
    Group {
      if chatModel.isLoadingRooms {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = chatModel.roomsError {
        VStack {
          Text(error)
            .foregroundColor(.red)
          Button("다시 시도") {
            Task { await chatModel.fetchRooms() }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if chatModel.rooms.isEmpty {
        Text("채팅방이 없습니다.")
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(chatModel.rooms) { room in
          Button {
            navigate(.push(ProfileRoute.chattingRoom(roomId: room.roomId)))
          } label: {
            ChatRoomCell(room: room)
          }
        }
        .listStyle(.plain)
      }
    }
    .navigationTitle("채팅")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          // 채팅방 생성/검색 등
        } label: {
          Image(systemName: "plus.bubble")
        }
      }
    }
    .onAppear {
      if chatModel.rooms.isEmpty {
        Task { await chatModel.fetchRooms() }
      }
    }
  }

}

// MARK: - 채팅방 셀
struct ChatRoomCell: View {
  let room: ChatRoom

  var body: some View {
    HStack(spacing: 12) {
      // 프로필 이미지 (첫번째 참여자)
      if let url = room.participants.first?.profileImage, !url.isEmpty {
        AsyncImage(url: URL(string: url)) { image in
          image.resizable()
        } placeholder: {
          Color.gray.opacity(0.2)
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
      } else {
        Circle()
          .fill(Color.gray.opacity(0.2))
          .frame(width: 48, height: 48)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(room.participants.first?.nick ?? "알 수 없음")
          .font(.headline)
        Text(room.lastMessage?.content ?? "")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
      Spacer()
      VStack(alignment: .trailing, spacing: 4) {
        Text(room.lastMessage?.createdAt.prefix(10) ?? "")
          .font(.caption)
          .foregroundColor(.secondary)
        if room.unreadCount > 0 {
          Text("\(room.unreadCount)")
            .font(.caption2)
            .foregroundColor(.white)
            .padding(6)
            .background(Circle().fill(Color.red))
        }
      }
    }
    .padding(.vertical, 8)
  }
}
