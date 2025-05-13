//
//  InputField.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/13/25.
//

import SwiftUI

// MARK: - 입력 필드 컴포넌트
struct InputField: View {
  enum ValidationState {
    case initial           // 초기 상태, 아직 검증되지 않음
    case editing           // 사용자가 입력 중
    case valid(message: String?)    // 유효한, 검증 통과
    case invalid(message: String)   // 유효하지 않음, 이유 포함
    case loading(message: String)   // 비동기 검증 중 (서버 검증 등)
    
    var message: String? {
      switch self {
      case .initial, .editing:
        return nil
      case .valid(let message):
        return message
      case .invalid(let message):
        return message
      case .loading(let message):
        return message
      }
    }
    
    var backgroundColor: Color {
      switch self {
      case .initial, .editing:
        return Color(.systemGray6)
      case .valid:
        return Color(.systemGray6).opacity(0.8)
      case .invalid:
        return Color(.systemGray6).opacity(0.9)
      case .loading:
        return Color(.systemGray6).opacity(0.7)
      }
    }
    
    var borderColor: Color {
      switch self {
      case .initial, .editing:
        return Color.clear
      case .valid:
        return Color.green.opacity(0.5)
      case .invalid:
        return Color.red
      case .loading:
        return Color.blue.opacity(0.5)
      }
    }
    
    var messageColor: Color {
      switch self {
      case .valid:
        return Color.green
      case .invalid:
        return Color.red
      case .loading:
        return Color.blue
      default:
        return Color.primary
      }
    }
    
    var isValid: Bool {
      if case .valid = self { return true }
      return false
    }
    
  }
  
  let title: String
  let placeholder: String
  @Binding var text: String
  @Binding var validationState: ValidationState
  var onValueChanged: ((String) -> Void)? = nil
  var keyboardType: UIKeyboardType = .default
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.headline)
        .foregroundColor(.primary)
      
      TextField(placeholder, text: $text)
        .keyboardType(keyboardType)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(validationState.backgroundColor)
        )
        .overlay {
          RoundedRectangle(cornerRadius: 12)
            .stroke(validationState.borderColor, lineWidth: 1)
        }
        .onChange(of: text) { newValue in
          // 값이 변경되면 editing 상태로 변경 (처음 입력 시)
          if case .initial = validationState {
            validationState = .editing
          }
          
          // 외부 검증 로직 호출
          onValueChanged?(newValue)
        }
      
      if let message = validationState.message {
        Text(message)
          .font(.subheadline)
          .foregroundStyle(validationState.messageColor)
          .padding(.leading)
      }
    }
  }
}

// MARK: - 비밀번호 필드 컴포넌트
struct PasswordField: View {
  let title: String
  let placeholder: String
  @Binding var text: String
  @Binding var validationState: InputField.ValidationState
  @Binding var showPassword: Bool
  var onValueChanged: ((String) -> Void)? = nil
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.headline)
        .foregroundColor(.primary)
      
      HStack {
        if showPassword {
          TextField(placeholder, text: $text)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        } else {
          SecureField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
        }
        
        Button {
          showPassword.toggle()
        } label: {
          Image(systemName: showPassword ? "eye.slash" : "eye")
            .foregroundColor(.gray)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(validationState.backgroundColor)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .stroke(validationState.borderColor, lineWidth: 1)
      }
      .onChange(of: text) { newValue in
        // 값이 변경되면 editing 상태로 변경 (처음 입력 시)
        if case .initial = validationState {
          validationState = .editing
        }
        
        // 외부 검증 로직 호출
        onValueChanged?(newValue)
      }
      
      if let message = validationState.message {
        Text(message)
          .font(.subheadline)
          .foregroundStyle(validationState.messageColor)
          .padding(.leading)
      }
    }
  }
}
