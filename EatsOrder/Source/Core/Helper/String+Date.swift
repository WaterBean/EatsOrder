//
//  String+Date.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import Foundation

// ISO8601 String -> Date 변환 헬퍼
public extension String {
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: self)
  }
}
