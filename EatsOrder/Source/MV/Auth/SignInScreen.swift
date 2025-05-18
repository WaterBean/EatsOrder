//
//  SignInScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import SwiftUI
import KakaoSDKUser
import KakaoSDKAuth
import AuthenticationServices

struct SignInScreen: View {
  @EnvironmentObject var authModel: AuthModel
  @State private var isShowingEmailLogin = false
  @State private var isShowingEmailSignup = false
  @State private var navigationPath = NavigationPath()
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack(path: $navigationPath) {
      SignInView(
        isShowingEmailLogin: $isShowingEmailLogin,
        isShowingEmailSignup: $isShowingEmailSignup,
        onKakaoLogin: performKakaoLogin,
        onAppleSignIn: handleAppleSignIn,
        onDismiss: { dismiss() }
      )
      .navigationDestination(isPresented: $isShowingEmailLogin) {
        EmailLoginScreen()
      }
      .navigationDestination(isPresented: $isShowingEmailSignup) {
        EmailSignUpScreen()
      }
      .onReceive(authModel.$loginSuccess) { success in
        if success { dismiss() }
      }
      .onReceive(authModel.$joinSuccess) { success in
        if success { isShowingEmailSignup = false }
      }
    }
  }
  
  private func performKakaoLogin() {
    // 로직 시작 전 상태 초기화
    authModel.dispatch(.clearError)
    authModel.dispatch(.setLoading(isLoading: true))
    
    if (UserApi.isKakaoTalkLoginAvailable()) {
      // 카카오톡 앱으로 로그인
      UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
        handleKakaoLoginResult(oauthToken: oauthToken, error: error)
      }
    } else {
      // TODO: - 카카오톡 앱이 없는 경우 카카오톡 설치로 유도
    }
  }
  
  // 카카오 로그인 결과 처리
  private func handleKakaoLoginResult(oauthToken: OAuthToken?, error: Error?) {
    // 에러 처리
    if let error = error {
      authModel.dispatch(.setLoading(isLoading: false))
      authModel.dispatch(.setError(message: "카카오 로그인 실패: \(error.localizedDescription)"))
      return
    }
    
    // 토큰 유효성 검사
    guard let token = oauthToken?.accessToken else {
      authModel.dispatch(.setLoading(isLoading: false))
      authModel.dispatch(.setError(message: "카카오 토큰을 가져오지 못했습니다"))
      return
    }
    
    // 서버에 카카오 토큰 전달
    Task {
      await authModel.kakaoLogin(oauthToken: token)
    }
  }
  
  private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
    switch result {
    case .success(let authorization):
      // Apple ID 인증 정보 확인
      if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
         let tokenData = appleIDCredential.identityToken,
         let idToken = String(data: tokenData, encoding: .utf8) {
        
        // 닉네임 추출 (첫 로그인 시에만 제공됨)
        var nickname: String? = nil
        if let fullName = appleIDCredential.fullName,
           let givenName = fullName.givenName {
          nickname = givenName
        }
        
        // 서버에 애플 토큰 전달
        Task {
          await authModel.appleLogin(idToken: idToken, nick: nickname)
        }
      } else {
        // 토큰 획득 실패
        authModel.dispatch(.setError(message: "애플 토큰을 가져오지 못했습니다"))
      }
      
    case .failure(let error):
      // 실패 처리
      authModel.dispatch(.setError(message: "애플 로그인 실패: \(error.localizedDescription)"))
    }
  }
}

extension SignInWithAppleButton {
    /// 애플 로그인 버튼을 앱의 디자인 스타일에 맞게 통일하는 모디파이어
    func customAppleButtonStyle(height: CGFloat = 50) -> some View {
        self
            .frame(height: height)
            .padding(.horizontal, 20)
            .clipShape(.capsule)
            
    }
}


struct SignInView: View {
  @Binding var isShowingEmailLogin: Bool
  @Binding var isShowingEmailSignup: Bool
  var onKakaoLogin: () -> Void
  var onAppleSignIn: (Result<ASAuthorization, Error>) -> Void
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
              onKakaoLogin()
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
          SignInWithAppleButton { request in
            request.requestedScopes = [.fullName, .email]
          } onCompletion: { result in
            onAppleSignIn(result)
          }
          .customAppleButtonStyle()
          .signInWithAppleButtonStyle(.white)
          
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

// **MARK: - 이메일 로그인 컨테이너**
struct EmailLoginScreen: View {
  @State private var email = ""
  @State private var password = ""
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var authModel: AuthModel
  
  var body: some View {
    EmailLoginView(
      email: $email,
      password: $password,
      isLoading: authModel.isLoading,
      errorMessage: authModel.errorMessage,
      onLogin: login,
      onDismiss: { dismiss() }
    )
    // 로그인 성공 시 화면 닫기
    .onReceive(authModel.$loginSuccess) { success in
      if success {
        // 로그인 성공 후 약간의 지연을 두고 화면 닫기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          dismiss()
          
          // 상태 초기화 (다음 로그인 시도를 위해)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            authModel.dispatch(.setLoginSuccess(success: false))
            authModel.dispatch(.clearError)
          }
        }
      }
    }
  }
  
  private func login() {
    // 키보드 숨기기
    hideKeyboard()
    
    // 로그인 로직 처리
    Task {
      await authModel.login(email: email, password: password)
      // dismiss는 onReceive에서 처리
    }
  }
  
  private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

// **MARK: - 이메일 로그인 뷰**
struct EmailLoginView: View {
  @Binding var email: String
  @Binding var password: String
  @State private var emailValidationState: InputField.ValidationState = .initial
  @State private var passwordValidationState: InputField.ValidationState = .initial
  var isLoading: Bool  // 로딩 상태 추가
  var errorMessage: String  // 에러 메시지 추가
  var onLogin: () -> Void
  var onDismiss: () -> Void
  
  @FocusState private var focusedField: Field?
  
  // 포커스 필드 열거형
  enum Field {
    case email, password
  }
  
  // 로그인 버튼 활성화 조건
  private var isLoginEnabled: Bool {
    // 기본 요구사항: 이메일과 비밀번호가 비어있지 않아야 함
    !email.isEmpty && !password.isEmpty && !isLoading
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
        .focused($focusedField, equals: .email)
        .submitLabel(.next)
        .onSubmit {
          focusedField = .password
        }
        
        // 비밀번호 입력 필드
        PasswordField(
          title: "비밀번호",
          placeholder: "비밀번호를 입력하세요",
          text: $password,
          validationState: $passwordValidationState,
          showPassword: .constant(false),
          onValueChanged: { newPassword in
            validatePassword(newPassword)
          }
        )
        .inspectable(false)
        .focused($focusedField, equals: .password)
        .submitLabel(.done)
        .onSubmit {
          if isLoginEnabled {
            onLogin()
          }
        }
      }
      .padding(.horizontal)
      
      // 에러 메시지 표시
      if !errorMessage.isEmpty {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
          .transition(.opacity)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
      }
      
      // 로그인 버튼
      Button(action: onLogin) {
        HStack {
          if isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .padding(.trailing, 8)
          }
          
          Text("로그인")
            .font(.headline)
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isLoginEnabled ? Color.black : Color.gray)
        .cornerRadius(12)
        .padding(.horizontal)
      }
      .disabled(!isLoginEnabled)
      
      Spacer()
    }
    .animation(.easeInOut, value: errorMessage)
    .onChange(of: isLoading) { _ in
      // 로딩이 끝났을 때 키보드 숨기기
      if !isLoading {
        focusedField = nil
      }
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
    if password.count < 8 {
      passwordValidationState = .invalid(message: "비밀번호는 8자리 이상입니다.")
    } else {
      // 로그인에서는 단순히 입력 여부만 확인
      passwordValidationState = .initial
    }
  }
}
