//
//  Font+.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/18/25.
//

import SwiftUI

extension Font {
  enum Pretendard {
    enum Size {
      static let title1: CGFloat = 20
      static let body1: CGFloat = 16
      static let body2: CGFloat = 14
      static let body3: CGFloat = 13
      static let caption1: CGFloat = 12
      static let caption2: CGFloat = 10
      static let caption3: CGFloat = 8
    }

    enum Weight {
      case bold
      case medium
      case regular

      var name: String {
        switch self {
        case .bold: return "Pretendard-Bold"
        case .medium: return "Pretendard-Medium"
        case .regular: return "Pretendard-Regular"
        }
      }
    }

    static func custom(_ size: CGFloat, weight: Weight = .medium) -> Font {
      .custom(weight.name, size: size)
    }

    /// 20pt 크기의 Pretendard-Bold 폰트 - 주요 제목에 사용
    static let title1: Font = custom(Size.title1, weight: .bold)

    /// 16pt 크기의 Pretendard-Medium 폰트 - 기본 본문 텍스트에 사용
    static let body1: Font = custom(Size.body1)

    /// 14pt 크기의 Pretendard-Medium 폰트 - 보조 본문 텍스트에 사용
    static let body2: Font = custom(Size.body2)

    /// 13pt 크기의 Pretendard-Medium 폰트 - 작은 본문 텍스트에 사용
    static let body3: Font = custom(Size.body3)

    /// 12pt 크기의 Pretendard-Regular 폰트 - 주요 캡션 텍스트에 사용
    static let caption1: Font = custom(Size.caption1, weight: .regular)

    /// 10pt 크기의 Pretendard-Regular 폰트 - 보조 캡션 텍스트에 사용
    static let caption2: Font = custom(Size.caption2, weight: .regular)

    /// 8pt 크기의 Pretendard-Regular 폰트 - 가장 작은 텍스트에 사용
    static let caption3: Font = custom(Size.caption3, weight: .regular)
  }

  enum Jalnan {
    enum Size {
      static let title1: CGFloat = 24
      static let body1: CGFloat = 20
      static let caption1: CGFloat = 14
    }

    static func custom(_ size: CGFloat) -> Font {
      .custom("JalnanGothic", size: size)
    }

    /// 24pt 크기의 JalnanGothic 폰트 - 대표 제목 및 강조 텍스트에 사용
    static let title1: Font = custom(Size.title1)

    /// 20pt 크기의 JalnanGothic 폰트 - 중요 본문 및 하위 제목에 사용
    static let body1: Font = custom(Size.body1)

    /// 14pt 크기의 JalnanGothic 폰트 - 작은 강조 텍스트 및 특별 캡션에 사용
    static let caption1: Font = custom(Size.caption1)
  }
}
