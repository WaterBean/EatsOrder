//
//  PickchelinLabel.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import SwiftUI

struct PickchelinLabel: View {
  var body: some View {
    ZStack(alignment: .leading) {
      Image("pickchelin-tag")
      HStack(spacing: 4) {
        Image("pick-fill")
          .resizable()
          .frame(width: 12, height: 12)
          .foregroundColor(.white)
        Text("픽슐랭")
          .font(.Pretendard.caption2)
          .foregroundColor(.white)
      }
      .padding([.vertical, .leading], 4)
    }
  }
}
