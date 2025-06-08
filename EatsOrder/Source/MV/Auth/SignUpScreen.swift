//
//  SignUpView.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import SwiftUI

// MARK: - 이메일 회원가입 화면
struct EmailSignUpScreen: View {
  @State private var state = EmailSignUpScreenState()
  @EnvironmentObject private var authModel: AuthModel
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          
          // 입력 폼 영역
          VStack(spacing: 16) {
            // 이메일 입력
            InputField(
              title: "이메일",
              placeholder: "example@email.com",
              text: $state.email,
              validationState: $state.emailValidationState,
              onValueChanged: { email in
                handleEmailChange(email)
              },
              keyboardType: .emailAddress
            )
            
            // 닉네임 입력
            InputField(
              title: "닉네임",
              placeholder: "닉네임을 입력하세요",
              text: $state.nick,
              validationState: $state.nickValidationState,
              onValueChanged: { nick in
                handleNickChange(nick)
              }
            )
            
            // 전화번호 입력 (선택사항)
            InputField(
              title: "전화번호 (선택사항)",
              placeholder: "01012341234",
              text: $state.phoneNum,
              validationState: $state.phoneNumValidationState,
              onValueChanged: { phoneNum in
                handlePhoneNumChange(phoneNum)
              },
              keyboardType: .decimalPad
            )
            
            // 비밀번호 입력
            PasswordField(
              title: "비밀번호",
              placeholder: "비밀번호를 입력하세요",
              text: $state.password,
              validationState: $state.passwordValidationState,
              showPassword: $state.showPassword,
              onValueChanged: { password in
                handlePasswordChange(password)
              }
            )
            
            // 비밀번호 확인 입력
            PasswordField(
              title: "비밀번호 확인",
              placeholder: "비밀번호를 다시 입력하세요",
              text: $state.confirmPassword,
              validationState: $state.confirmPasswordValidationState,
              showPassword: $state.showConfirmPassword,
              onValueChanged: { confirmPassword in
                handleConfirmPasswordChange(confirmPassword)
              }
            )
          }
          .padding(.horizontal)
          
          // 회원가입 버튼
          Button {
            signUp()
          } label: {
            if state.isLoading {
              ProgressView()
                .tint(.white)
            } else {
              Text("회원가입")
                .fontWeight(.semibold)
            }
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(state.isFormValid ? Color.blue : Color.blue.opacity(0.5))
          .foregroundColor(.white)
          .cornerRadius(12)
          .disabled(!state.isFormValid || state.isLoading)
          .padding(.horizontal)
        }
      }
      .navigationTitle("회원가입")
      .navigationBarTitleDisplayMode(.inline)
      .scrollDismissesKeyboard(.immediately)
    }
  }
}

// MARK: - View 확장 (View 관련 로직)
extension EmailSignUpScreen {
  // 이메일 값 변경 핸들러
  private func handleEmailChange(_ email: String) {
    // 로컬 유효성 검사
    if email.isEmpty {
      state.emailValidationState = .invalid(message: "이메일을 입력해주세요.")
      return
    }
    
    if !state.isEmailValid {
      state.emailValidationState = .invalid(message: "유효한 이메일 형식이 아닙니다.")
      return
    }
    
    // 이메일 형식이 유효하면 서버 중복 확인
    state.emailValidationState = .loading(message: "이메일 확인 중...")
    
    // 서버 API 호출 - 디바운싱 구현 필요
    Task {
      await checkEmailDuplication(email)
    }
  }
  
  // 닉네임 값 변경 핸들러
  private func handleNickChange(_ nick: String) {
    if nick.isEmpty {
      state.nickValidationState = .invalid(message: "닉네임을 입력해주세요.")
      return
    }
    
    // 닉네임에는 특정 문자를 사용할 수 없음
    let invalidCharacters: [Character] = [".", ",", "?", "*", "-", "@"]
    if invalidCharacters.contains(where: { nick.contains($0) }) {
      state.nickValidationState = .invalid(message: "닉네임에는 ., ,, ?, *, -, @ 문자를 사용할 수 없습니다.")
      return
    }
    
    // 유효한 닉네임
    state.nickValidationState = .valid(message: nil)
  }
  
  // 전화번호 값 변경 핸들러
  private func handlePhoneNumChange(_ phoneNum: String) {
    // 전화번호는 선택 사항이므로 비어있어도 유효
    if phoneNum.isEmpty {
      state.phoneNumValidationState = .valid(message: nil)
      return
    }
    
    // 숫자만 포함되어 있는지 확인 (하이픈 제외)
    let phoneNumDigitsOnly = phoneNum.replacingOccurrences(of: "-", with: "")
    if !phoneNumDigitsOnly.allSatisfy({ $0.isNumber }) {
      state.phoneNumValidationState = .invalid(message: "전화번호는 숫자만 입력 가능합니다.")
      return
    }
    
    if phoneNumDigitsOnly.count < 10 || phoneNumDigitsOnly.count > 11 {
      state.phoneNumValidationState = .invalid(message: "유효한 전화번호 형식이 아닙니다.")
      return
    }
    
    // 유효한 전화번호
    state.phoneNumValidationState = .valid(message: nil)
  }
  
  // 비밀번호 값 변경 핸들러
  private func handlePasswordChange(_ password: String) {
    if password.isEmpty {
      state.passwordValidationState = .invalid(message: "비밀번호를 입력해주세요.")
      return
    }
    
    if password.count < 8 {
      state.passwordValidationState = .invalid(message: "비밀번호는 최소 8자 이상이어야 합니다.")
      return
    }
    
    // 영문자, 숫자, 특수문자 각각 1개 이상 포함 확인
    let letterRegex = ".*[A-Za-z].*"
    let numberRegex = ".*[0-9].*"
    let specialCharRegex = ".*[@$!%*#?&].*"
    
    let letterPredicate = NSPredicate(format: "SELF MATCHES %@", letterRegex)
    let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
    let specialCharPredicate = NSPredicate(format: "SELF MATCHES %@", specialCharRegex)
    
    if !letterPredicate.evaluate(with: password) ||
       !numberPredicate.evaluate(with: password) ||
       !specialCharPredicate.evaluate(with: password) {
      state.passwordValidationState = .invalid(message: "비밀번호는 영문자, 숫자, 특수문자(@$!%*#?&)를 각각 1개 이상 포함해야 합니다.")
      return
    }
    
    // 유효한 비밀번호
    state.passwordValidationState = .valid(message: nil)
    
    // 비밀번호가 변경되면 확인 비밀번호도 다시 검증
    handleConfirmPasswordChange(state.confirmPassword)
  }
  
  // 비밀번호 확인 값 변경 핸들러
  private func handleConfirmPasswordChange(_ confirmPassword: String) {
    if confirmPassword.isEmpty {
      state.confirmPasswordValidationState = .invalid(message: "비밀번호 확인을 입력해주세요.")
      return
    }
    
    if confirmPassword != state.password {
      state.confirmPasswordValidationState = .invalid(message: "비밀번호가 일치하지 않습니다.")
      return
    }
    
    // 유효한 비밀번호 확인
    state.confirmPasswordValidationState = .valid(message: nil)
  }
  
  // 이메일 중복 확인
  private func checkEmailDuplication(_ email: String) async {
    // 입력이 변경되었거나 빈 값이면 API 호출 무시
    guard !email.isEmpty, state.isEmailValid else { return }
    
    // 서버 중복 체크 API 호출
    await authModel.emailValidation(email: email)
    
    // API 응답 결과를 상태에 반영
    if authModel.emailValidationResult.contains("사용 가능") {
      state.emailValidationState = .valid(message: authModel.emailValidationResult)
    } else {
      state.emailValidationState = .invalid(message: authModel.emailValidationResult)
    }
  }
  
  // 회원가입 기능
  private func signUp() {
    // 폼이 유효하지 않으면 중단
    guard state.isFormValid else { print("검증 실패"); return }
    
    state.isLoading = true
    
    // 회원가입 API 호출
    Task {
        await authModel.join(
          email: state.email,
          password: state.password,
          nick: state.nick,
          phoneNum: state.phoneNum,
          deviceToken: ""
        )
        await MainActor.run {
          state.isLoading = false
          // 회원가입 성공 처리 (예: 화면 닫기 또는 로그인 화면으로 이동)
          dismiss()
        }
      // TODO: - 실패 시 예외처리 로직도 필요
    }
  }
  
}

// MARK: - 상태 구조체
struct EmailSignUpScreenState {
  // 입력 값
  var email: String = ""
  var password: String = ""
  var confirmPassword: String = ""
  var nick: String = ""
  var phoneNum: String = ""
  
  // 유효성 상태
  var emailValidationState: InputField.ValidationState = .initial
  var passwordValidationState: InputField.ValidationState = .initial
  var confirmPasswordValidationState: InputField.ValidationState = .initial
  var nickValidationState: InputField.ValidationState = .initial
  var phoneNumValidationState: InputField.ValidationState = .initial
  
  // UI 상태
  var showPassword: Bool = false
  var showConfirmPassword: Bool = false
  var isLoading: Bool = false
  
  // 이메일 형식 확인
  var isEmailValid: Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: email)
  }
  
  var isFormValid: Bool {
    // 각 필드의 유효성 상태 확인
    let isEmailValid = emailValidationState.isValid
    let isNickValid = nickValidationState.isValid
    let isPasswordValid = passwordValidationState.isValid
    let isConfirmPasswordValid = confirmPasswordValidationState.isValid
    
    // 전화번호는 선택사항
    let isPhoneNumValid = phoneNum.isEmpty || phoneNumValidationState.isValid
    
    // 모든 필수 필드가 유효해야 함
    return isEmailValid && isNickValid &&
           isPasswordValid && isConfirmPasswordValid &&
           isPhoneNumValid
  }

}

#if DEBUG
#Preview {
  EmailSignUpScreen()
    .environmentObject(AuthModel(service: NetworkService(session: URLSession.shared), tokenManager: TokenManager()))
}
#endif
