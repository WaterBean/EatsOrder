//
//  LikeButton.swift
//  EatsOrder
//
//  Created by Assistant on current date.
//

import SwiftUI

// MARK: - Like Button Component with Optimistic Update
struct LikeButton: View {
  // Initial state
  let isLiked: Bool
  
  // Async action handler that returns success/failure
  let onToggle: () async throws -> Void
  
  // Optional customization
  var size: CGFloat = 24
  var padding: CGFloat = 8
  var likedColor: Color = .blackSprout
  var unlikedColor: Color = .g30
  var animationScale: CGFloat = 1.3
  
  // Local state for optimistic update
  @State private var localIsLiked: Bool
  @State private var isProcessing: Bool = false
  @State private var showHeartBurst: Bool = false
  @State private var animationScale: CGFloat = 1.0
  @State private var rotationAngle: Double = 0
  
  init(
    isLiked: Bool,
    size: CGFloat = 24,
    padding: CGFloat = 8,
    likedColor: Color = .blackSprout,
    unlikedColor: Color = .g30,
    onToggle: @escaping () async throws -> Void
  ) {
    self.isLiked = isLiked
    self.size = size
    self.padding = padding
    self.likedColor = likedColor
    self.unlikedColor = unlikedColor
    self.onToggle = onToggle
    self._localIsLiked = State(initialValue: isLiked)
  }
  
  var body: some View {
    Button(action: handleToggle) {
      ZStack {
        // Heart burst effect when liked
        if showHeartBurst {
          ForEach(0..<8, id: \.self) { index in
            Image(systemName: "heart.fill")
              .foregroundColor(likedColor.opacity(0.6))
              .font(.system(size: size * 0.4))
              .offset(heartBurstOffset(for: index))
              .opacity(showHeartBurst ? 0 : 1)
              .scaleEffect(showHeartBurst ? 1.5 : 0.5)
              .animation(
                .easeOut(duration: 0.6).delay(Double(index) * 0.05),
                value: showHeartBurst
              )
          }
        }
        
        // Main heart icon
        Image(localIsLiked ? "like-fill" : "like-empty")
          .resizable()
          .frame(width: size, height: size)
          .foregroundColor(localIsLiked ? likedColor : unlikedColor)
          .scaleEffect(animationScale)
          .rotationEffect(.degrees(rotationAngle))
          .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animationScale)
          .animation(.easeInOut(duration: 0.2), value: rotationAngle)
      }
      .padding(padding)
    }
    .disabled(isProcessing)
    .onChange(of: isLiked) { newValue in
      // Sync with parent state changes
      if !isProcessing {
        localIsLiked = newValue
      }
    }
  }
  
  private func handleToggle() {
    guard !isProcessing else { return }
    
    // Haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
    
    // Optimistic update - immediately update UI
    isProcessing = true
    let newState = !localIsLiked
    
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
      localIsLiked = newState
      animationScale = animationScale == 1.0 ? 1.2 : 1.0
      
      if newState {
        rotationAngle = 15
        showHeartBurst = true
      } else {
        rotationAngle = -15
      }
    }
    
    // Reset animation states
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      withAnimation {
        animationScale = 1.0
        rotationAngle = 0
      }
    }
    
    if newState {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        showHeartBurst = false
      }
    }
    
    // Perform async operation
    Task {
      do {
        try await onToggle()
        // Success - keep the optimistic state
        await MainActor.run {
          isProcessing = false
        }
      } catch {
        // Failure - revert to original state
        await MainActor.run {
          withAnimation(.easeInOut(duration: 0.2)) {
            localIsLiked = !newState // Revert
            
            // Shake animation for error
            withAnimation(.default.repeatCount(2, autoreverses: true)) {
              rotationAngle = localIsLiked ? -5 : 5
            }
          }
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            rotationAngle = 0
          }
          
          isProcessing = false
          
          // Optional: Show error feedback
          let errorFeedback = UINotificationFeedbackGenerator()
          errorFeedback.notificationOccurred(.error)
        }
      }
    }
  }
  
  private func heartBurstOffset(for index: Int) -> CGSize {
    let angle = Double(index) * (360.0 / 8.0) * .pi / 180
    let distance: CGFloat = showHeartBurst ? size * 1.5 : 0
    return CGSize(
      width: cos(angle) * distance,
      height: sin(angle) * distance
    )
  }
}

// MARK: - Convenience initializer for sync actions
extension LikeButton {
  init(
    isLiked: Bool,
    size: CGFloat = 24,
    padding: CGFloat = 8,
    likedColor: Color = .blackSprout,
    unlikedColor: Color = .g30,
    onToggle: @escaping () -> Void
  ) {
    self.init(
      isLiked: isLiked,
      size: size,
      padding: padding,
      likedColor: likedColor,
      unlikedColor: unlikedColor,
      onToggle: {
        onToggle()
      }
    )
  }
}

// MARK: - Preview
struct LikeButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 40) {
      // Standard like button
      LikeButton(isLiked: false) {
        print("Like toggled")
      }
      
      // Liked state
      LikeButton(isLiked: true) {
        print("Like toggled")
      }
      
      // Custom size and colors
      LikeButton(
        isLiked: false,
        size: 32,
        padding: 12,
        likedColor: .red,
        unlikedColor: .gray
      ) {
        print("Custom like toggled")
      }
      
      // With async action
      LikeButton(isLiked: false) {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        // Randomly fail for demo
        if Bool.random() {
          throw NSError(domain: "test", code: 0)
        }
      }
    }
    .padding()
  }
}