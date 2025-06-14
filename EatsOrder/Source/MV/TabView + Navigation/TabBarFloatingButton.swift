//
//  TabBarFloatingButton.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import SwiftUI

// 플로팅 버튼
struct TabBarFloatingButton: View {
  let onTap: () -> Void
  let cartCount: Int
  let animation: Namespace.ID
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.blackSprout)
        .frame(width: 56, height: 56)
        .matchedGeometryEffect(id: "cartFab", in: animation)
      Image(systemName: "cart")
        .foregroundColor(.white)
      if cartCount > 0 {
        Circle()
          .fill(Color.white)
          .frame(width: 20, height: 20)
          .offset(x: 20, y: -20)
        Text("\(cartCount)")
          .font(.caption2.weight(.bold))
          .foregroundColor(.blackSprout)
          .offset(x: 20, y: -20)
      }
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .shadow(radius: 4, y: 2)
    .onTapGesture { onTap() }
  }
}

