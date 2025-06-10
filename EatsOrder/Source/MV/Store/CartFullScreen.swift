//
//  CartFullScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/10.
//

import SwiftUI

struct CartFullScreen: View {
  @EnvironmentObject private var orderModel: OrderModel
  let animation: Namespace.ID
  let cart: Cart?
  let onUpdateQuantity: (String, Int) -> Void
  let onRemove: (String) -> Void
  let onClose: () -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.blackSprout
        .matchedGeometryEffect(id: "cartFab", in: animation)
        .ignoresSafeArea()
      VStack {
        HStack {
          Spacer()
          Button(action: onClose) {
            Image(systemName: "xmark")
              .foregroundColor(.white)
              .padding()
              .background(Color.black.opacity(0.3), in: Circle())
          }
        }
        .padding(.top, 60)
        .padding(.trailing, 24)
        Spacer(minLength: 0)
        VStack(spacing: 0) {
          Text("장바구니")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
            .padding(.bottom, 16)
          if let cart = cart, !cart.items.isEmpty {
            ScrollView {
              VStack(spacing: 0) {
                ForEach(cart.items) { item in
                  HStack {
                    Text(item.name)
                      .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                      if item.quantity > 1 { onUpdateQuantity(item.id, item.quantity - 1) }
                    }) {
                      Image(systemName: "minus.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                    }
                    Text("\(item.quantity)")
                      .foregroundColor(.white)
                      .frame(width: 32)
                    Button(action: { onUpdateQuantity(item.id, item.quantity + 1) }) {
                      Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                    }
                    Button(action: { onRemove(item.id) }) {
                      Image(systemName: "trash")
                        .foregroundColor(.red)
                    }
                  }
                  .padding(.vertical, 12)
                  .padding(.horizontal, 24)
                  Divider().background(Color.white.opacity(0.2))
                }
              }
            }
            .frame(maxHeight: 320)
            Text("총 금액: \(cart.totalPrice)원")
              .font(.title2)
              .foregroundColor(.white)
              .padding()
          } else {
            Text("장바구니가 비어있습니다")
              .foregroundColor(.white)
              .padding()
          }
        }
        Spacer()
        Button(action: {
          // TODO: 주문하기 버튼 클릭 시 주문 화면으로 이동
          //router.push(.order)
        }) {
          Text("주문하기")
            .font(.title3.bold())
            .foregroundColor(.blackSprout)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
        }
        .padding(.bottom, 40)
      }
    }
  }
}
