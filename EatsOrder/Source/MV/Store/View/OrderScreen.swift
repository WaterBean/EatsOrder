import SwiftUI

struct OrderScreen: View {
  @EnvironmentObject var orderModel: OrderModel
  @Environment(\.navigate) private var navigate

  var currentOrders: [Order] {
    orderModel.orderList.filter { $0.isActive }
  }
  var previousOrders: [Order] {
    orderModel.orderList.filter { !$0.isActive }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // 픽업 안내
        pickupNoticeView()
          .padding(.top, 16)

        // 진행중 주문 캐러셀
        if !currentOrders.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
              ForEach(currentOrders, id: \.id) { order in
                CurrentOrderCardView(order: order)
                  .padding(.horizontal, 16)
              }
            }
          }
        } else {
          emptyCurrentOrderView()
            .padding(.horizontal, 16)
        }

        // 이전 주문 내역
        VStack(alignment: .leading, spacing: 12) {
          Text("이전주문 내역")
            .font(.Pretendard.body2.weight(.bold))
            .foregroundColor(.g60)
            .padding(.leading, 16)

          if previousOrders.isEmpty {
            emptyOrderHistoryView()
              .padding(.horizontal, 16)
          } else {
            ForEach(previousOrders) { order in
              OrderHistoryCardView(order: order) { action in
                switch action {
                case .writeReview:
                  // 리뷰 작성 화면 이동 등
                  break
                }
              }
              .padding(.horizontal, 16)
            }
          }
        }
        .padding(.top, 8)
      }
      .padding(.bottom, 80)
    }
    .background(Color.g0.ignoresSafeArea())
    .task {
      await orderModel.fetchOrderList()
    }
  }

  // 픽업 안내 뷰
  private func pickupNoticeView() -> some View {
    HStack {
      Text("픽업을 하실 때는")
        .font(.Jalnan.caption1)
        .foregroundColor(.g75)
      Text("주문번호")
        .font(.Jalnan.caption1)
        .foregroundColor(.deepSprout)
      Text("를 꼭 말씀해주세요!")
        .font(.Jalnan.caption1)
        .foregroundColor(.g75)
      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.brightSprout.opacity(0.15))
    )
    .padding(.horizontal, 16)
  }

  // 진행중 주문 없을 때
  private func emptyCurrentOrderView() -> some View {
    VStack(spacing: 12) {
      Image(systemName: "cart")
        .resizable()
        .frame(width: 48, height: 48)
        .foregroundColor(.g30)
      Text("진행중인 주문이 없습니다")
        .font(.Pretendard.body2)
        .foregroundColor(.g60)
    }
    .frame(maxWidth: .infinity)
    .padding(32)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    )
  }

  // 이전 주문 없을 때
  private func emptyOrderHistoryView() -> some View {
    VStack(spacing: 12) {
      Image(systemName: "clock")
        .resizable()
        .frame(width: 40, height: 40)
        .foregroundColor(.g30)
      Text("이전 주문 내역이 없습니다")
        .font(.Pretendard.body2)
        .foregroundColor(.g60)
    }
    .frame(maxWidth: .infinity)
    .padding(32)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    )
  }
}

// MARK: - 진행중 주문 카드

struct CurrentOrderCardView: View {
  let order: Order

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .center, spacing: 4) {
        // 타임라인 + 메뉴 썸네일
        HStack(alignment: .top, spacing: 16) {
          VStack(alignment: .leading, spacing: 4) {
            Text("주문번호 \(order.orderCode)")
              .font(.Jalnan.caption1)
              .foregroundColor(.g60)
            Text(order.store.name)
              .font(.Jalnan.body1)
              .foregroundColor(.blackSprout)
            Text(order.createdAt.formatted(date: .long, time: .shortened))
              .font(.Pretendard.caption1)
              .foregroundColor(.g30)

            //가게 이미지
            if let storeImage = order.store.storeImageUrls.first {
              CachedAsyncImage(url: storeImage) { image in
                image.resizable().scaledToFill()
              } placeholder: {
                Color.g15
              }
              .frame(width: 126, height: 126)
              .clipShape(RoundedRectangle(cornerRadius: 16))
            }
          }
          OrderStatusTimelineView(statuses: order.statusTimeline)
            .frame(width: 140, height: 200)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.g15)
            )
        }
      }
      // 메뉴 리스트
      VStack(alignment: .leading, spacing: 8) {
        ForEach(order.items, id: \.id) { menu in
          HStack {
            Text(menu.name)
              .font(.Pretendard.body3)
              .foregroundColor(.g90)
            Spacer()
            Text("\(menu.price.formatted())원  \(menu.quantity)EA")
              .font(.Pretendard.body3)
              .foregroundColor(.g60)
          }
        }
      }

      Divider()

      // 결제금액
      HStack {
        Text("결제금액")
          .font(.Pretendard.body2)
          .foregroundColor(.g60)
        Spacer()
        Text("\(order.items.reduce(0) { $0 + $1.quantity })EA  \(order.totalPrice.formatted())원")
          .font(.Pretendard.body2.weight(.bold))
          .foregroundColor(.blackSprout)
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.brightSprout, lineWidth: 1)
        )
    )
  }
}

// MARK: - 주문 상태 타임라인

struct OrderStatusTimelineView: View {
  let statuses: [StatusTimeline]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(statuses) { status in
        HStack(alignment: .center, spacing: 8) {
          Circle()
            .fill(status.isCompleted ? Color.blackSprout : Color.g30)
            .frame(width: 16, height: 16)
          Text(status.status.displayName)
            .font(.Pretendard.caption2.weight(.semibold))
            .foregroundColor(status.isCompleted ? .blackSprout : .g90)
          if status.isCompleted, let changedAt = status.changedAt {
            Text(changedAt.formatted(date: .omitted, time: .shortened))
              .font(.Pretendard.caption2.weight(.medium))
              .foregroundColor(.g60)
          }

        }
        if status != statuses.last {
          Rectangle()
            .fill(Color.g30)
            .frame(width: 2, height: 20)
            .padding(.leading, 7)
        }
      }
    }

  }
}

// MARK: - 주문 내역 카드

struct OrderHistoryCardView: View {
  let order: Order
  let onAction: (Action) -> Void

  enum Action { case writeReview }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text(order.store.name)
            .font(.Pretendard.title1)
            .foregroundColor(.g75)
          HStack {
            Text(order.orderCode)
              .font(.Pretendard.caption1.weight(.semibold))
              .foregroundColor(.g30)
            Text(order.createdAt.formatted(date: .long, time: .shortened))
              .font(.Pretendard.caption1.weight(.semibold))
              .foregroundColor(.g45)
          }
          HStack {
            Text("\(order.items.first?.name ?? "") 외 \(order.items.count-1)건")
              .font(.Pretendard.caption1.weight(.semibold))
              .foregroundColor(.g45)
            Text("\(order.totalPrice.formatted())원")
              .font(.Pretendard.caption1.weight(.semibold))
              .foregroundColor(.blackSprout)
            Image(systemName: "chevron.right")
              .foregroundColor(.blackSprout)
          }
        }
        Spacer()
        CachedAsyncImage(url: order.store.storeImageUrls.first ?? "") { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.g15
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))

      }
      if order.canWriteReview {
        Button {
          onAction(.writeReview)
        } label: {
          Text("리뷰 작성")
            .font(.Pretendard.body3.weight(.bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.deepSprout)
            )
        }
      } else if order.review.rating > 0 {
        HStack(spacing: 4) {
          Image(systemName: "star.fill")
            .foregroundColor(.brightForsythia)
          Text(String(format: "%d", order.review.rating))
            .font(.Pretendard.body3.weight(.bold))
            .foregroundColor(.g90)
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    )

  }
}
