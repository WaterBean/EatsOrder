//
//  EatsOrderTab+ChildView.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import SwiftUI

// 커스텀 탭 정의
enum EatsOrderTab: Int, CaseIterable {
  case home = 0
  case order = 1
  case community = 2
  case profile = 3
  
  var title: String {
    switch self {
    case .home: return "홈"
    case .order: return "리스트"
    case .community: return "친구"
    case .profile: return "프로필"
    }
  }
  
  var iconName: String {
    switch self {
    case .home: return "home-fill"
    case .order: return "order-fill"
    case .community: return "community-fill"
    case .profile: return "profile-fill"
    }
  }
}

// View 확장
extension EatsOrderTab {
  @ViewBuilder
  var view: some View {
    switch self {
    case .home: Color.red
    case .order: Color.green
    case .community: Color.blue
    case .profile: Color.purple
    }
  }
}
