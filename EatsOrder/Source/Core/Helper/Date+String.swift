//
//  Date+.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import Foundation

public extension Date {
  var iso8601String: String {
    ISO8601DateFormatter().string(from: self)
  }
}

