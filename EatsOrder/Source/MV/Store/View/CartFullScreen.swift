//
//  CartFullScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/10.
//

import SwiftUI
import WebKit
import iamport_ios

struct PaymentRequest: Entity {
  let pg: String
  let merchant_uid: String
  let amount: Int
  let pay_method: String
  let name: String
  let buyer_name: String
  let app_scheme: String
  var id: String { merchant_uid }
}

struct PaymentWebViewModeView: UIViewControllerRepresentable {
  let userCode: String
  let orderCode: String
  let totalPrice: Int
  let storeName: String
  let onResult: (IamportResponse) -> Void

  func makeUIViewController(context: Context) -> PaymentWebViewModeViewController {
    PaymentWebViewModeViewController(
      userCode: userCode,
      orderCode: orderCode,
      totalPrice: totalPrice,
      storeName: storeName,
      onResult: onResult
    )
  }

  func updateUIViewController(
    _ uiViewController: PaymentWebViewModeViewController, context: Context
  ) {}
}

final class PaymentWebViewModeViewController: UIViewController, WKNavigationDelegate {
  let userCode: String
  let orderCode: String
  let totalPrice: Int
  let storeName: String
  let onResult: (IamportResponse) -> Void

  private lazy var wkWebView: WKWebView = {
    let view = WKWebView()
    view.backgroundColor = UIColor.clear
    view.navigationDelegate = self
    return view
  }()

  init(
    userCode: String,
    orderCode: String,
    totalPrice: Int,
    storeName: String,
    onResult: @escaping (IamportResponse) -> Void
  ) {
    self.userCode = userCode
    self.orderCode = orderCode
    self.totalPrice = totalPrice
    self.storeName = storeName
    self.onResult = onResult
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    attachWebView()
    requestPayment()
  }

  private func attachWebView() {
    view.addSubview(wkWebView)
    wkWebView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      wkWebView.topAnchor.constraint(equalTo: view.topAnchor),
      wkWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      wkWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      wkWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  func requestPayment() {
    let payment = IamportPayment(
      pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
      merchant_uid: orderCode,
      amount: "\(totalPrice)"
    ).then {
      $0.pay_method = "card"
      $0.name = storeName
      $0.buyer_name = "한수빈"
      $0.app_scheme = "taylor.EatsOrder"
    }

    Iamport.shared.paymentWebView(webViewMode: wkWebView, userCode: userCode, payment: payment) {
      [weak self] response in
      if let response = response {
        self?.onResult(response)
      }
      self?.dismiss(animated: true)
    }
  }
}

struct CartFullScreen: View {
  @EnvironmentObject private var orderModel: OrderModel
  @Environment(\.navigate) private var navigate
  let animation: Namespace.ID
  let cart: Cart?
  let onUpdateQuantity: (String, Int) -> Void
  let onRemove: (String) -> Void
  let onClose: () -> Void
  let onPaymentSuccess: () -> Void

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
          Task { await orderModel.preparePayment() }
        }) {
          Text("주문하기")
            .font(.title3.bold())
            .foregroundColor(.blackSprout)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
        }
        .disabled(cart == nil || cart?.items.isEmpty == true)
        .padding(.bottom, 40)
      }
    }
    .fullScreenCover(item: $orderModel.pendingPayment) { payment in
      PaymentWebViewModeView(
        userCode: "imp14511373",
        orderCode: payment.orderCode,
        totalPrice: payment.totalPrice,
        storeName: payment.storeName,
        onResult: { response in
          Task { await orderModel.handlePaymentCallback(response: response) }
        }
      )
    }
    .alert(
      isPresented: Binding<Bool>(
        get: { (orderModel.paymentResult?.success == false) },
        set: { newValue in if !newValue { orderModel.paymentResult = nil } }
      )
    ) {
      Alert(
        title: Text("결제 실패"),
        message: Text(orderModel.paymentResult?.message ?? "알 수 없는 오류"),
        dismissButton: .default(Text("확인"))
      )
    }
    .onChange(of: orderModel.paymentResult?.success) { newSuccess in
      if newSuccess == true {
        onPaymentSuccess()
      }
    }
  }
}
