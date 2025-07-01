//
//  SearchBarView.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/05/27.
//

import SwiftUI

struct SearchBarView: View {
  let searchText: String
  let onSearchTextChanged: (String) -> Void

  @State private var text: String = ""

  var body: some View {
      HStack(spacing: 10) {
        Image("search")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundStyle(.blackSprout)
          .padding(.leading, 16)

        TextField("검색어를 입력해주세요.", text: $text)
          .font(.Pretendard.body2)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .frame(height: 40)
          .onChange(of: text) { newValue in
            onSearchTextChanged(newValue)
          }
      }
      .background(
        RoundedRectangle(cornerRadius: 25)
          .strokeBorder(Color.blackSprout, lineWidth: 1)
          .background(Color.white)
          .clipShape(Capsule())
      )

    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .padding(.horizontal, 20)
      
    .onAppear { text = searchText }
  }
}

