//
//  Environments.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/9/25.
//

import Foundation

enum Environments {
  static var apiKey: String {
    Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as! String
  }
  static var baseURL: String {
    Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as! String
  }
  static var kakaoNativeAppKey: String {
    Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as! String
  }
}
