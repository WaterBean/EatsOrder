//
//  NavigateAction.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import SwiftUI

public struct NavigateAction {
  public typealias Action = (NavigationType) -> Void
  let action: Action
  func callAsFunction(_ navigationType: NavigationType) {
    action(navigationType)
  }
}

public struct NavigateEnvironmentKey: EnvironmentKey {
  public static var defaultValue: NavigateAction = NavigateAction(action: { _ in })
}

public extension EnvironmentValues {
  var navigate: (NavigateAction) {
    get { self[NavigateEnvironmentKey.self] }
    set { self[NavigateEnvironmentKey.self] = newValue }
  }
}

