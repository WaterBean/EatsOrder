//
//  SectionHeaderView.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/05/27.
//

import SwiftUI

struct SectionHeaderView: View {
  let title: String
  var trailing: AnyView? = nil

  init(title: String) {
    self.title = title
    self.trailing = nil
  }

  init<T: View>(title: String, trailing: T) {
    self.title = title
    self.trailing = AnyView(trailing)
  }

  var body: some View {
    HStack {
      Text(title)
        .font(.Pretendard.body1.weight(.bold))
        .padding(.leading, 20)
        .foregroundStyle(.g90)

      Spacer()

      if let trailing = trailing {
        trailing
          .padding(.trailing, 20)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 32)
  }
}
