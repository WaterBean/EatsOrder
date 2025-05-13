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
  var onLogin: () -> Void
  var onDismiss: () -> Void
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text("이메일로 로그인")
          .font(.title)
          .fontWeight(.bold)
          .padding(.top, 40)
        
        VStack(spacing: 16) {
          TextField("이메일", text: $email)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
          
          SecureField("비밀번호", text: $password)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        
        Button(action: onLogin) {
          Text("로그인")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        
        Spacer()
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: onDismiss) {
            Image(systemName: "xmark")
          }
        }
      }
    }
  }
}

#if DEBUG
#Preview {
  SignInScreen()
}
#endif
