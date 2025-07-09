//
//  View+Navigation.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import SwiftUI

public extension View {
  func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
    self.environment(\.navigate, NavigateAction(action: action))
  }
}
