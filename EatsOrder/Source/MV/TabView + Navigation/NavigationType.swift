//
//  Navigate.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/24/25.
//

import SwiftUI

enum NavigationType: Hashable {
  case push(AnyHashable)
  case unwind(AnyHashable)
}

struct NavigateAction {
  typealias Action = (NavigationType) -> Void
  let action: Action
  func callAsFunction(_ navigationType: NavigationType) {
    action(navigationType)
  }
}

struct NavigateEnvironmentKey: EnvironmentKey {
  static var defaultValue: NavigateAction = NavigateAction(action: { _ in })
}

extension EnvironmentValues {
  var navigate: (NavigateAction) {
    get { self[NavigateEnvironmentKey.self] }
    set { self[NavigateEnvironmentKey.self] = newValue }
  }
}

extension UINavigationController: @retroactive ObservableObject, @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isHidden = true
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

extension View {
  func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
    self.environment(\.navigate, NavigateAction(action: action))
  }
}
