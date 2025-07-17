//
//  TabNavigationStack.swift
//  EatsOrder
//
//  Created by 한수빈 on 7/1/25.
//

import SwiftUI

struct HomeNavigationStack: View {
  @EnvironmentObject private var router: Router
  var body: some View {
    NavigationStack(path: $router.homePath) {
      StoreExploreScreen()
        .background(.brightSprout)
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
      OrderScreen()
        .navigationDestination(for: OrderRoute.self) { route in
          switch route {
          case .main:
            OrderScreen()
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
      ProfileScreen()
        .onNavigate { navType in
          switch navType {
          case .push(let route):
            if let navigatedRoute = route as? ProfileRoute {
              router.profilePath.append(navigatedRoute)
            }
          case .unwind:
            router.profilePath.removeLast()
          }
        }
        .navigationDestination(for: ProfileRoute.self) { $0.destinationScreen() }
      
    }
  }
}
