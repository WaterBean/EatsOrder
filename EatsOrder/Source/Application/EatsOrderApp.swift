//
//  EatsOrderApp.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import SwiftUI

@main
struct EatsOrderApp: App {
  @StateObject var authModel = AuthModel(service: .shared)
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(authModel)
    }
  }
}
