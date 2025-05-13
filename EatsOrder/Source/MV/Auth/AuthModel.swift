//
//  AuthModel.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import Foundation

@MainActor
final class AuthModel: ObservableObject {
  
  @Published var emailValidationResult: String = ""
  let service: NetworkService
  
  init(service: NetworkService) {
    self.service = service
  }
  
  func emailValidation(email: String) async {
    do {
      let response: MessageResponse = try await service.request(endpoint: UserEndpoint.validateEmail(email: email))
      emailValidationResult = response.message
    } catch {
      print(error.localizedDescription)
      emailValidationResult = error.localizedDescription
    }
    
  }
}

enum AuthModelError: Error {
  case emailValidationFailed
}
