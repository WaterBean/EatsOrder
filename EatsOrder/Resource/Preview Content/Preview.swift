//
//  Preview.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/25/25.
//

import SwiftUI

struct EatsOrderPreviewScreen: View {

  @StateObject private var authModel: AuthModel
  @StateObject private var profileModel: ProfileModel
  @StateObject private var storeModel: StoreModel
  @StateObject private var locationManager = LocationManager.shared
  init() {
    // 의존성 설정
    let setup = DependencySetup()
    let (authModel, profileModel, storeModel) = setup.setupDependencies()

    // StateObject 초기화
    self._authModel = StateObject(wrappedValue: authModel)
    self._profileModel = StateObject(wrappedValue: profileModel)
    self._storeModel = StateObject(wrappedValue: storeModel)
  }

  var body: some View {

    EatsOrderTabContainer()
      .environmentObject(authModel)
      .environmentObject(profileModel)
      .environmentObject(storeModel)
      .environmentObject(locationManager)
  }
}

#Preview("StoreDetailScreen") {
  let setup = DependencySetup()
  let (_, _, storeModel) = setup.setupDependencies()

  return StoreDetailScreen(storeId: "682313acca81ef0db5a45c9b")
    .environmentObject(storeModel)
    .environmentObject(LocationManager.shared)
}

#Preview {
  EatsOrderPreviewScreen()
}
