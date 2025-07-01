//
//  UINavigationController+Gesture.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import SwiftUI

// 네비게이션바를 숨겼을 때, 제스처가 동작하지 않는 현상을 해결하기 위한 확장

public extension UINavigationController: @retroactive ObservableObject, @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isHidden = true
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
