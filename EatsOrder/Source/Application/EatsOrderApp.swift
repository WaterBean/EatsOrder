//
//  EatsOrderApp.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import SwiftUI

@main
struct EatsOrderApp: App {
  @StateObject var authModel = AuthModel(service: NetworkService(session: URLSession.shared), tokenManager: TokenManager())
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(authModel)
    }
  }
}
