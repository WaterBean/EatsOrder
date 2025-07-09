//
//  ScreenSize.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import SwiftUI

public var screenWidth: CGFloat {
  UIScreen.main.bounds.width
}

public var screenHeight: CGFloat {
  UIScreen.main.bounds.height
}

public var screenTopPadding: CGFloat {
  UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
}
