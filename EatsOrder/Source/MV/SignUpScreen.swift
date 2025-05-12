//
//  SignUpView.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/12/25.
//

import SwiftUI

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
              validateText: state.emailValidationText,
              keyboardType: .emailAddress
            )
            .onChange(of: state.email) { newValue in
              validateEmail(email: newValue)
            }
            
            // 닉네임 입력
            InputField(
              title: "닉네임",
              placeholder: "닉네임을 입력하세요",
              text: $state.nick,
              validateText: state.nickValidationText
            )
            .onChange(of: state.nick) { _ in
              state.validateNick()
            }
            
            // 전화번호 입력 (선택사항)
            InputField(
              title: "전화번호",
              placeholder: "01012341234",
              text: $state.phoneNum,
              validateText: state.phoneNumValidationText,
              keyboardType: .decimalPad
            )
            .onChange(of: state.phoneNum) { _ in
              state.validatePhoneNum()
            }
            
            // 비밀번호 입력
            PasswordField(
              title: "비밀번호",
              placeholder: "비밀번호를 입력하세요",
              text: $state.password,
              showPassword: $state.showPassword,
              validateText: state.passwordValidationText
            )
            .onChange(of: state.password) { _ in
              state.validatePassword()
            }
            
            // 비밀번호 확인 입력
            PasswordField(
              title: "비밀번호 확인",
              placeholder: "비밀번호를 다시 입력하세요",
              text: $state.confirmPassword,
              showPassword: $state.showConfirmPassword,
              validateText: state.confirmPasswordValidationText
            )
            .onChange(of: state.confirmPassword) { _ in
              state.validateConfirmPassword()
            }
            
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
  // 이메일 유효성 검사 (로컬 + 서버 중복 체크)
  private func validateEmail(email: String) {
    // 우선 로컬에서 형식 검사
    state.validateEmail()
    
    // 형식이 유효하면 서버에서 중복 체크
    if state.isEmailValid {
      Task {
        await checkEmailDuplication(email: email)
      }
    }
  }
  
  // TODO: - Combine으로 리팩토링
  private func checkEmailDuplication(email: String) async {
    // 입력이 변경되었거나 빈 값이면 API 호출 무시
    guard !email.isEmpty, state.isEmailValid else { return }
    
    // 임시 검증 텍스트 설정
    await MainActor.run {
      state.emailValidationText = "이메일 확인 중..."
    }
    
    // 서버 중복 체크 API 호출
    await authModel.emailValidation(email: email)
    
    // API 응답 결과를 상태에 반영
    await MainActor.run {
      state.emailValidationText = authModel.emailValidationResult
    }
    
  }
  
  // 회원가입 기능
  private func signUp() {
    // 최종 유효성 검사
    state.validateAllFields()
    
    guard state.isFormValid else { return }
    
    state.isLoading = true
    
    // 회원가입 API 호출 (실제로는 AuthModel의 signUp 메서드 호출)
    Task {
      // await authModel.signUp(email: state.email, password: state.password, nick: state.nick, phoneNum: state.phoneNum)
      
      // 임시 지연 (실제 구현에서는 제거)
      try? await Task.sleep(nanoseconds: 1_500_000_000)
      
      await MainActor.run {
        state.isLoading = false
        // 회원가입 성공 처리 (예: 화면 닫기 또는 로그인 화면으로 이동)
        dismiss()
      }
    }
  }
}

// MARK: - 상태 구조체
struct EmailSignUpScreenState {
  var email: String = ""
  var password: String = ""
  var confirmPassword: String = ""
  var nick: String = ""
  var phoneNum: String = ""
  
  var emailValidationText: String = ""
  var passwordValidationText: String = ""
  var confirmPasswordValidationText: String = ""
  var nickValidationText: String = ""
  var phoneNumValidationText: String = ""
  
  var showPassword: Bool = false
  var showConfirmPassword: Bool = false
  var isLoading: Bool = false
  
  var isEmailValid: Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: email)
  }
  
  var isNickValid: Bool {
    // `.`, `,`, `?`, `*`, `-`, `@`는 nick으로 사용할 수 없음
    let invalidCharacters: [Character] = [".", ",", "?", "*", "-", "@"]
    return !nick.isEmpty && !invalidCharacters.contains(where: { nick.contains($0) })
  }
  
  var isPasswordValid: Bool {
    guard password.count >= 8 else { return false }
    
    // 영문자, 숫자, 특수문자(@$!%*#?&) 각각 1개 이상 포함
    let letterRegex = ".*[A-Za-z].*"
    let numberRegex = ".*[0-9].*"
    let specialCharRegex = ".*[@$!%*#?&].*"
    
    let letterPredicate = NSPredicate(format: "SELF MATCHES %@", letterRegex)
    let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
    let specialCharPredicate = NSPredicate(format: "SELF MATCHES %@", specialCharRegex)
    
    return letterPredicate.evaluate(with: password) &&
    numberPredicate.evaluate(with: password) &&
    specialCharPredicate.evaluate(with: password)
  }
  
  var isConfirmPasswordValid: Bool {
    return !confirmPassword.isEmpty && password == confirmPassword
  }
  
  // 전체 폼이 유효한지 확인
  var isFormValid: Bool {
    return isEmailValid &&
    isNickValid &&
    isPasswordValid &&
    isConfirmPasswordValid &&
    !emailValidationText.contains("이미 사용 중") && // 서버 중복 체크 결과도 반영
    !emailValidationText.contains("확인 중") // 서버 확인 중이 아님
  }
  
  // 이메일 변경 시 유효성 검사
  mutating func validateEmail() {
    if email.isEmpty {
      emailValidationText = "이메일을 입력해주세요."
    } else if !isEmailValid {
      emailValidationText = "유효한 이메일 형식이 아닙니다."
    } else {
      // 서버 검증 결과가 있으면 유지, 없으면 비움
      if !emailValidationText.contains("사용 가능") && !emailValidationText.contains("이미 사용 중") {
        emailValidationText = ""
      }
    }
  }
  
  // 닉네임 변경 시 유효성 검사
  mutating func validateNick() {
    if nick.isEmpty {
      nickValidationText = "닉네임을 입력해주세요."
    } else if !isNickValid {
      nickValidationText = "닉네임에는 ., ,, ?, *, -, @ 문자를 사용할 수 없습니다."
    } else {
      nickValidationText = ""
    }
  }
  
  // 비밀번호 변경 시 유효성 검사
  mutating func validatePassword() {
    if password.isEmpty {
      passwordValidationText = "비밀번호를 입력해주세요."
    } else if password.count < 8 {
      passwordValidationText = "비밀번호는 최소 8자 이상이어야 합니다."
    } else if !isPasswordValid {
      passwordValidationText = "비밀번호는 영문자, 숫자, 특수문자(@$!%*#?&)를 각각 1개 이상 포함해야 합니다."
    } else {
      passwordValidationText = ""
    }
    
    // 비밀번호가 변경되면 확인 비밀번호도 다시 검증
    validateConfirmPassword()
  }
  
  // 비밀번호 확인 변경 시 유효성 검사
  mutating func validateConfirmPassword() {
    if confirmPassword.isEmpty {
      confirmPasswordValidationText = "비밀번호 확인을 입력해주세요."
    } else if password != confirmPassword {
      confirmPasswordValidationText = "비밀번호가 일치하지 않습니다."
    } else {
      confirmPasswordValidationText = ""
    }
  }
  
  // 전화번호 변경 시 유효성 검사 (선택 사항)
  mutating func validatePhoneNum() {
    // 전화번호는 선택 사항이므로 비어있어도 오류 메시지 없음
    if phoneNum.isEmpty {
      phoneNumValidationText = ""
      return
    }
    
    // 숫자만 포함되어 있는지 확인 (하이픈 제외)
    let phoneNumDigitsOnly = phoneNum.replacingOccurrences(of: "-", with: "")
    if !phoneNumDigitsOnly.allSatisfy({ $0.isNumber }) {
      phoneNumValidationText = "전화번호는 숫자만 입력 가능합니다."
    } else if phoneNumDigitsOnly.count < 10 || phoneNumDigitsOnly.count > 11 {
      phoneNumValidationText = "유효한 전화번호 형식이 아닙니다."
    } else {
      phoneNumValidationText = ""
    }
  }
  
  // 모든 유효성 검사를 한 번에 수행
  mutating func validateAllFields() {
    validateEmail()
    validateNick()
    validatePassword()
    validateConfirmPassword()
    validatePhoneNum()
  }
}

// 재사용 가능한 텍스트 필드 컴포넌트
struct InputField: View {
  let title: String
  let placeholder: String
  @Binding var text: String
  let validateText: String
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
            .fill(Color(.systemGray6))
        )
      Text(validateText)
        .font(.subheadline)
        .foregroundColor(.primary)
        .padding(.leading)
      
    }
  }
}

// 재사용 가능한 비밀번호 필드 컴포넌트
struct PasswordField: View {
  let title: String
  let placeholder: String
  @Binding var text: String
  @Binding var showPassword: Bool
  let validateText: String
  
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
          .fill(Color(.systemGray6))
      )
      Text(validateText)
        .font(.subheadline)
        .foregroundColor(.primary)
        .padding(.leading)
      
    }
  }
}

#if DEBUG
#Preview {
  EmailSignUpScreen()
    .environmentObject(AuthModel(service: .shared))
}
#endif
