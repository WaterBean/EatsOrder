//
//  Navigate.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/24/25.
//

import SwiftUI

public enum NavigationType: Hashable {
  case push(AnyHashable)
  case unwind(AnyHashable)
}

