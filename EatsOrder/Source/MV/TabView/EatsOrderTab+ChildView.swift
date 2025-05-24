//
//  EatsOrderTab+ChildView.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import SwiftUI

// 커스텀 탭 정의
enum EatsOrderTab: Int, Hashable, CaseIterable {
  case home = 0
  case order = 1
  case community = 2
  case profile = 3
  
  var iconName: String {
    switch self {
    case .home: return "home-fill"
    case .order: return "order-fill"
    case .community: return "community-fill"
    case .profile: return "profile-fill"
    }
  }
}

// 탭별 라우트 정의
enum HomeRoute: Hashable { case main, locationSelect }
enum OrderRoute: Hashable { case main }
enum CommunityRoute: Hashable { case main }
enum ProfileRoute: Hashable { case main }

extension HomeRoute {
  @ViewBuilder
  func destinationScreen() -> some View {
    switch self {
    case .main:
      MainHomeScreen()
    case .locationSelect:
      LocationSelectView()
    }
  }
}

// 탭별 path를 관리하는 라우터
final class Router: ObservableObject {
  @Published var homePath: [HomeRoute] = []
  @Published var orderPath: [OrderRoute] = []
  @Published var communityPath: [CommunityRoute] = []
  @Published var profilePath: [ProfileRoute] = []
}

// View 확장
extension EatsOrderTab {
  @ViewBuilder
  var screen: some View {
    switch self {
    case .home:
      HomeNavigationStack()
    case .order:
      OrderNavigationStack()
    case .community:
      CommunityNavigationStack()
    case .profile:
      ProfileNavigationStack()
    }
  }
}

struct HomeNavigationStack: View {
  @EnvironmentObject private var router: Router
  var body: some View {
    NavigationStack(path: $router.homePath) {
      MainHomeScreen()
        .onNavigate { navType in
          switch navType {
          case .push(let route):
            if let navigatedRoute = route as? HomeRoute {
              router.homePath.append(navigatedRoute)
            }
          case .unwind:
            router.homePath.removeLast()
          }
        }
        .navigationDestination(for: HomeRoute.self) { $0.destinationScreen() }
    }
  }
}

struct OrderNavigationStack: View {
  @EnvironmentObject private var router: Router
  var body: some View {
    NavigationStack(path: $router.orderPath) {
      Color.green
        .navigationDestination(for: OrderRoute.self) { route in
          switch route {
          case .main:
            Color.green
          }
        }
    }
  }
}

struct CommunityNavigationStack: View {
  @EnvironmentObject private var router: Router
  var body: some View {
    NavigationStack(path: $router.communityPath) {
      Color.blue
        .navigationDestination(for: CommunityRoute.self) { route in
          switch route {
          case .main:
            Color.blue
          }
        }
    }
  }
}

struct ProfileNavigationStack: View {
  @EnvironmentObject private var router: Router
  var body: some View {
    NavigationStack(path: $router.profilePath) {
      Color.purple
        .navigationDestination(for: ProfileRoute.self) { route in
          switch route {
          case .main:
            Color.purple
          }
        }
    }
  }
}