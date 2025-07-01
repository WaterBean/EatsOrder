//
//  TabBarHiddenModifier.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import SwiftUI

// 커스텀 탭바의 숨김 상태를 관리하는 모디파이어
private struct IsTabBarHiddenKey: EnvironmentKey {
  static let defaultValue: Binding<Bool> = .constant(false)
}

public extension EnvironmentValues {
  var isTabBarHidden: Binding<Bool> {
    get { self[IsTabBarHiddenKey.self] }
    set { self[IsTabBarHiddenKey.self] = newValue }
  }
}

private struct TabBarHiddenModifier: ViewModifier {
  let hidden: Bool
  @Environment(\.isTabBarHidden) private var isTabBarHidden

  func body(content: Content) -> some View {
    content
      .onAppear { isTabBarHidden.wrappedValue = hidden }
      .onDisappear { isTabBarHidden.wrappedValue = !hidden }
  }
}

public extension View {
  func tabBarHidden(_ hidden: Bool = true) -> some View {
    self.modifier(TabBarHiddenModifier(hidden: hidden))
  }
}
