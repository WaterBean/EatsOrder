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
  @StateObject private var locationModel: LocationModel
  @StateObject private var orderModel: OrderModel
  @StateObject private var chatModel: ChatModel
  init() {
    // 의존성 설정
    let setup = DependencySetup()
    let (authModel, profileModel, storeModel, locationModel, orderModel, chatModel) = setup.setupDependencies()

    // StateObject 초기화
    self._authModel = StateObject(wrappedValue: authModel)
    self._profileModel = StateObject(wrappedValue: profileModel)
    self._storeModel = StateObject(wrappedValue: storeModel)
    self._locationModel = StateObject(wrappedValue: locationModel)
    self._orderModel = StateObject(wrappedValue: orderModel)
    self._chatModel = StateObject(wrappedValue: chatModel)
  }

  var body: some View {

    EatsOrderTabContainer()
      .environmentObject(authModel)
      .environmentObject(profileModel)
      .environmentObject(storeModel)
      .environmentObject(locationModel)
      .environmentObject(orderModel)
      .environmentObject(chatModel)
  }
}

#Preview("StoreDetailScreen") {
  let setup = DependencySetup()
  let (_, _, storeModel, _, _, _) = setup.setupDependencies()

  return StoreDetailScreen(storeId: "682313acca81ef0db5a45c9b")
    .environmentObject(storeModel)
}

#Preview {
  EatsOrderPreviewScreen()
}
