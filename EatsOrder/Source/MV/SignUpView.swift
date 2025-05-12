//
//  SignUpView.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import SwiftUI

struct SignUpScreen: View {
  @State private var email: String = ""
  @State private var password: String = ""
  @State private var confirmPassword: String = ""
  @State private var nick: String = ""
  @State private var phoneNum: String = ""
  @State private var deviceToken: String = ""
  @State private var agreeToTerms: Bool = false
  @State private var showPassword: Bool = false
  @State private var showConfirmPassword: Bool = false
  @State private var isLoading: Bool = false
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // 로고 영역
          Image(systemName: "person.crop.circle.badge.plus")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .foregroundColor(.blue)
            .padding(.top, 20)
          
          Text("회원가입")
            .font(.largeTitle)
            .fontWeight(.bold)
          
          // 입력 폼 영역
          VStack(spacing: 16) {
            // 이메일 입력
            InputField(
              title: "이메일",
              placeholder: "example@email.com",
              icon: "envelope",
              text: $email,
              keyboardType: .emailAddress
            )
            
            // 닉네임 입력
            InputField(
              title: "닉네임",
              placeholder: "닉네임을 입력하세요",
              icon: "person",
              text: $nick
            )
            
            // 전화번호 입력 (선택사항)
            InputField(
              title: "전화번호 (선택사항)",
              placeholder: "01012341234",
              icon: "phone",
              text: $phoneNum,
              keyboardType: .phonePad,
              isOptional: true
            )
            
            // 비밀번호 입력
            PasswordField(
              title: "비밀번호",
              placeholder: "비밀번호를 입력하세요",
              text: $password,
              showPassword: $showPassword
            )
            
            // 비밀번호 확인 입력
            PasswordField(
              title: "비밀번호 확인",
              placeholder: "비밀번호를 다시 입력하세요",
              text: $confirmPassword,
              showPassword: $showConfirmPassword
            )
            
            // 약관 동의
            HStack {
              Button {
                agreeToTerms.toggle()
              } label: {
                HStack(alignment: .top, spacing: 8) {
                  Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreeToTerms ? .blue : .gray)
                  
                  Text("이용약관과 개인정보 처리방침에 동의합니다.")
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                  
                  Spacer()
                }
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal)
          
          // 회원가입 버튼
          Button {
            signUp()
          } label: {
            if isLoading {
              ProgressView()
                .tint(.white)
            } else {
              Text("회원가입")
                .fontWeight(.semibold)
            }
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(isFormValid ? Color.blue : Color.blue.opacity(0.5))
          .foregroundColor(.white)
          .cornerRadius(12)
          .disabled(!isFormValid || isLoading)
          .padding(.horizontal)
          
          // 로그인 화면으로 이동
          HStack(spacing: 4) {
            Text("이미 계정이 있으신가요?")
              .foregroundColor(.secondary)
            
            Button {
              dismiss()
            } label: {
              Text("로그인")
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }
          }
          .padding(.bottom, 20)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "chevron.left")
              .foregroundColor(.blue)
          }
        }
      }
      .scrollDismissesKeyboard(.immediately)
    }
  }
  
  // 입력 폼 유효성 검사
  private var isFormValid: Bool {
    !email.isEmpty &&
    email.contains("@") &&
    !nick.isEmpty &&
    !password.isEmpty &&
    password.count >= 8 &&
    password == confirmPassword &&
    agreeToTerms
  }
  
  // 회원가입 기능
  private func signUp() {
    isLoading = true
    
    // 회원가입 DTO 생성
    let signUpDTO: [String: Any] = [
      "email": email,
      "password": password,
      "nick": nick,
      "phoneNum": phoneNum.isEmpty ? NSNull() : phoneNum,
      "deviceToken": deviceToken.isEmpty ? NSNull() : deviceToken
    ]
    
    // JSON 변환 및 로그 출력
    if let jsonData = try? JSONSerialization.data(withJSONObject: signUpDTO),
       let jsonString = String(data: jsonData, encoding: .utf8) {
      print("회원가입 DTO: \(jsonString)")
    }
    
    // 여기에 실제 API 호출 코드 구현
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      isLoading = false
      // 회원가입 성공 처리
    }
  }
}

// 재사용 가능한 텍스트 필드 컴포넌트
struct InputField: View {
  let title: String
  let placeholder: String
  let icon: String
  @Binding var text: String
  var keyboardType: UIKeyboardType = .default
  var isOptional: Bool = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(title)
          .font(.headline)
          .foregroundColor(.primary)
        
        if isOptional {
          Text("(선택)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      HStack {
        Image(systemName: icon)
          .foregroundColor(.gray)
        
        TextField(placeholder, text: $text)
          .keyboardType(keyboardType)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.systemGray6))
      )
    }
  }
}

// 재사용 가능한 비밀번호 필드 컴포넌트
struct PasswordField: View {
  let title: String
  let placeholder: String
  @Binding var text: String
  @Binding var showPassword: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.headline)
        .foregroundColor(.primary)
      
      HStack {
        Image(systemName: "lock")
          .foregroundColor(.gray)
        
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
          .fill(Color(.systemGray6))
      )
    }
  }
}

#Preview {
  SignUpScreen()
}
