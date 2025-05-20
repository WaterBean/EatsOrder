//
//  TabBarFloatingButton.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import SwiftUI

// 플로팅 버튼
struct TabBarFloatingButton: View {
  var body: some View {
    Button(action: {
      // 액션
    }) {
      ZStack {
        Circle()
          .fill(.blackSprout)
          .frame(width: 56, height: 56)
          .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        
        Image("pick-fill")
          .foregroundStyle(.white)
      }
    }
  }
}
