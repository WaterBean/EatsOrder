//
//  Response.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

struct Message: Decodable {
  let message: String
}

// ISO8601 String -> Date 변환 헬퍼
extension String {
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: self)
  }
}
