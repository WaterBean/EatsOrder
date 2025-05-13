//
//  SignInScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import SwiftUI

struct SignInScreen: View {
  @State private var isShowingEmailLogin = false
  @State private var isShowingEmailSignup = false
  @State private var navigationPath = NavigationPath()
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack(path: $navigationPath) {
      SignInView(
        isShowingEmailLogin: $isShowingEmailLogin,
        isShowingEmailSignup: $isShowingEmailSignup,
        onDismiss: { dismiss() }
      )
      .navigationDestination(isPresented: $isShowingEmailLogin) {
        EmailLoginContainer()
      }
      .navigationDestination(isPresented: $isShowingEmailSignup) {
        EmailSignUpScreen()
      }
    }
  }
}

struct SignInView: View {
  @Binding var isShowingEmailLogin: Bool
  @Binding var isShowingEmailSignup: Bool
  var onDismiss: () -> Void
  
  var body: some View {
    ZStack {
      // 배경 이미지 (어두운 배경)
      Color.black.opacity(0.9)
        .ignoresSafeArea()
      
      // 흐릿한 배경 이미지 (차량 이미지)
      Image(systemName: "person") // 적절한 이미지로 변경하세요
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: screenWidth)
        .opacity(0.3)
        .blur(radius: 3)
        .ignoresSafeArea()
      
      VStack(spacing: 30) {
        // 상단 닫기 버튼
        HStack {
          Button {
            onDismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 20))
              .foregroundColor(.white)
              .padding(.leading, 20)
          }
          Spacer()
        }
        
        Spacer()
        
        // 중앙 타이틀
        VStack(spacing: 16) {
          Text("기다리지 않는 VIP가 되는 법")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
          
          Text("잇츠오더")
            .font(.system(size: 38, weight: .bold))
            .foregroundColor(.white)
        }
        
        Spacer()
        
        // 로그인 버튼들
        VStack(spacing: 16) {
          // 카카오 로그인 버튼
          SignInButton(
            text: "카카오로 3초만에 로그인",
            icon: "message.fill",
            backgroundColor: .yellow,
            foregroundColor: .black,
            action: {
              // 카카오 로그인 액션
            }
          )
          
          // 마지막 로그인 정보
          Text("마지막 로그인 2025.05.12")
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(8)
            .background(Color.orange.opacity(0.8))
            .cornerRadius(20)
          
          // Apple 로그인 버튼
          SignInButton(
            text: "Apple로 로그인",
            icon: "apple.logo",
            backgroundColor: .white,
            foregroundColor: .black,
            action: {
              // Apple 로그인 액션
            }
          )
          
          // 이메일 로그인 버튼
          SignInButton(
            text: "이메일로 로그인",
            icon: "envelope",
            backgroundColor: .clear,
            foregroundColor: .white,
            hasBorder: true,
            action: {
              isShowingEmailLogin = true
            }
          )
          
          // 이메일로 회원가입 버튼
          Button {
            isShowingEmailSignup = true
          } label: {
            Text("이메일로 회원가입하기")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.white)
              .padding(.top, 8)
          }
        }
        
        Spacer()
        
        // 하단 인디케이터
        RoundedRectangle(cornerRadius: 3)
          .frame(width: 100, height: 6)
          .foregroundColor(.white.opacity(0.5))
          .padding(.bottom, 10)
      }
    }
  }
}

// MARK: - 재사용 가능한 버튼 컴포넌트
struct SignInButton: View {
  var text: String
  var icon: String
  var backgroundColor: Color
  var foregroundColor: Color
  var hasBorder: Bool = false
  var action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 18))
          .foregroundColor(foregroundColor)
        
        Text(text)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(foregroundColor)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(backgroundColor)
      .cornerRadius(30)
      .overlay(
        Group {
          if hasBorder {
            RoundedRectangle(cornerRadius: 30)
              .stroke(Color.white, lineWidth: 1)
          }
        }
      )
    }
    .padding(.horizontal, 24)
  }
}

// MARK: - 이메일 로그인 컨테이너
struct EmailLoginContainer: View {
  @State private var email = ""
  @State private var password = ""
  @Environment(\.dismiss) private var dismiss
  
  func login() {
    // 로그인 로직 처리
    dismiss()
  }
  
  var body: some View {
    EmailLoginView(
      email: $email,
      password: $password,
      onLogin: login,
      onDismiss: { dismiss() }
    )
  }
}

// MARK: - 이메일 로그인 뷰
struct EmailLoginView: View {
  @Binding var email: String
  @Binding var password: String
  @State private var emailValidationState: InputField.ValidationState = .initial
  @State private var passwordValidationState: InputField.ValidationState = .initial
  var onLogin: () -> Void
  var onDismiss: () -> Void
  
  // 로그인 버튼 활성화 조건
  private var isLoginEnabled: Bool {
    // 기본 요구사항: 이메일과 비밀번호가 비어있지 않아야 함
    !email.isEmpty && !password.isEmpty
  }
  
  var body: some View {
    VStack(spacing: 24) {
      Text("이메일로 로그인")
        .font(.title)
        .fontWeight(.bold)
        .padding(.top, 40)
      
      VStack(spacing: 16) {
        // 이메일 입력 필드
        InputField(
          title: "이메일",
          placeholder: "example@email.com",
          text: $email,
          validationState: $emailValidationState,
          onValueChanged: { newEmail in
            validateEmail(newEmail)
          },
          keyboardType: .emailAddress
        )
        
        // 비밀번호 입력 필드
        PasswordField(
          title: "비밀번호",
          placeholder: "비밀번호를 입력하세요",
          text: $password,
          validationState: $passwordValidationState,
          showPassword: .constant(false),  // 로그인 화면에서는 보통 비밀번호 표시를 허용하지 않음
          onValueChanged: { newPassword in
            validatePassword(newPassword)
          }
        )
      }
      .padding(.horizontal)
      
      // 로그인 버튼
      Button(action: onLogin) {
        Text("로그인")
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(isLoginEnabled ? Color.black : Color.gray)
          .cornerRadius(12)
          .padding(.horizontal)
      }
      .disabled(!isLoginEnabled)
      
      Spacer()
    }
  }
  
  // 이메일 유효성 검사 - 로그인에서는 간단하게 구현
  private func validateEmail(_ email: String) {
    if email.isEmpty {
      emailValidationState = .invalid(message: "이메일을 입력해주세요.")
    } else {
      // 로그인에서는 형식 검사만 간단히 수행
      let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
      let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
      
      if emailPredicate.evaluate(with: email) {
        emailValidationState = .initial  // 메시지 없이 유효 상태로 설정
      } else {
        emailValidationState = .invalid(message: "유효한 이메일 형식이 아닙니다.")
      }
    }
  }
  
  // 비밀번호 유효성 검사 - 로그인에서는 입력 여부만 확인
  private func validatePassword(_ password: String) {
    if password.count >= 8 {
      passwordValidationState = .invalid(message: "비밀번호를 입력해주세요.")
    } else {
      // 로그인에서는 단순히 입력 여부만 확인
      passwordValidationState = .initial
    }
  }
}
#if DEBUG
#Preview {
  SignInScreen()
}
#endif
