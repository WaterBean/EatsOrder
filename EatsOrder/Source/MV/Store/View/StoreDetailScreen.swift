//
//
//  StoreDetailScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/05/27.
//

import SwiftUI

// MARK: - Screen (Container)
struct StoreDetailScreen: View {
  let storeId: String
  @EnvironmentObject private var storeModel: StoreModel
  @EnvironmentObject private var orderModel: OrderModel
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: Router
  @State private var showCartSheet: Bool = false
  @State private var stepperVisible: [String: Bool] = [:]  // 메뉴별 stepper 상태
  @State private var timerDict: [String: Timer] = [:]
  @Namespace var animation

  private func menuQuantity(menuId: String) -> Int {
    guard let cart = orderModel.cart else { return 0 }
    return cart.items.first(where: { $0.id == menuId })?.quantity ?? 0
  }

  var body: some View {
    let detail = storeModel.storeDetails[storeId] ?? StoreDetail.empty
    StoreDetailView(
      detail: detail,
      onBack: { dismiss() },
      onLikeToggled: {
        Task {
          try? await storeModel.toggleStoreLike(
            storeId: storeId,
            currentLikeStatus: detail.isPick
          )
        }
      },
      menuCellProvider: { menu in
        let quantity = menuQuantity(menuId: menu.id)
        let isStepper = stepperVisible[menu.id] ?? false
        return MenuCellView(
          menu: menu,
          quantity: quantity,
          stepperVisible: Binding(
            get: { stepperVisible[menu.id] ?? false },
            set: { newValue in stepperVisible[menu.id] = newValue }
          ),
          onAdd: {
            if let cart = orderModel.cart, cart.id == menu.storeId,
              let idx = cart.items.firstIndex(where: { $0.id == menu.id })
            {
              orderModel.updateMenuQuantity(menuId: menu.id, quantity: cart.items[idx].quantity + 1)
            } else {
              let cartMenu = CartMenuItem(
                id: menu.id,
                name: menu.name,
                price: menu.price,
                quantity: 1,
                isSoldOut: menu.isSoldOut
              )
              orderModel.addMenuToCart(
                storeId: menu.storeId,
                storeName: detail.name ?? "",
                menu: cartMenu
              )
            }
            stepperVisible[menu.id] = true
            timerDict[menu.id]?.invalidate()
            timerDict[menu.id] = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
              stepperVisible[menu.id] = false
            }
          },
          onRemove: {
            if let cart = orderModel.cart, cart.id == menu.storeId,
              let idx = cart.items.firstIndex(where: { $0.id == menu.id })
            {
              let newQty = cart.items[idx].quantity - 1
              if newQty > 0 {
                orderModel.updateMenuQuantity(menuId: menu.id, quantity: newQty)
              } else {
                orderModel.removeMenuFromCart(menuId: menu.id)
              }
            }
            stepperVisible[menu.id] = true
            timerDict[menu.id]?.invalidate()
            timerDict[menu.id] = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
              stepperVisible[menu.id] = false
            }
          }
        )
      },
      cart: orderModel.cart,
      onCartPay: {
        showCartSheet = true
      }
    )
    .sheet(isPresented: $showCartSheet) {
      CartFullScreen(
        animation: animation, cart: orderModel.cart,
        onUpdateQuantity: { menuId, quantity in
          orderModel.updateMenuQuantity(menuId: menuId, quantity: quantity)
        },
        onRemove: { menuId in orderModel.removeMenuFromCart(menuId: menuId) },
        onClose: { showCartSheet = false },
        onPaymentSuccess: {
          showCartSheet = false
          router.homePath.removeAll()
          router.selectedTab = .order
        }
      )
    }
    .task {
      let fetched = await storeModel.fetchDetail(storeId: storeId)
      await MainActor.run {
        storeModel.storeDetails[storeId] = fetched
      }
    }
    .navigationBarBackButtonHidden(true)
    .tabBarHidden()
    .ignoresSafeArea()
  }
}

// MARK: - View (Presenter)
struct StoreDetailView: View {
  let detail: StoreDetail
  let onBack: () -> Void
  let onLikeToggled: () -> Void
  let menuCellProvider: (MenuItem) -> MenuCellView
  let cart: Cart?
  let onCartPay: () -> Void
  @State private var scrollY: CGFloat = 0
  @State private var selectedCategory: String? = nil
  @State private var isHeaderPressed: Bool = false
  @State private var isPressedCategory: String? = nil

  var categories: [String] {
    let all = detail.menuList.map { $0.category }
    return Array(NSOrderedSet(array: all)) as? [String] ?? []
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(pinnedViews: [.sectionHeaders]) {
            // 1. 상단 대표 이미지 + 커스텀 헤더
            ZStack(alignment: .top) {
              ImageCarouselView(detail: detail)
                .frame(height: 240)
                .clipped()
              // 커스텀 헤더 (사진 위에 오버레이)
              HStack {
                Button(action: onBack) {
                  Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
                }
                Spacer()
                LikeButton(
                  isLiked: detail.isPick,
                  size: 24,
                  padding: 0,
                  likedColor: .blackSprout,
                  unlikedColor: .white
                ) {
                  onLikeToggled()
                }
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
              }
              .padding(.horizontal, 16)
              .padding(.top, 44)  // 노치/상단 safe area 고려
            }

            // 2. 나머지 정보/카테고리/메뉴 등 기존 내용
            VStack(spacing: 0) {
              // 가게명/픽슐랭/통계
              VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                  Text(detail.name ?? "")
                    .font(.Pretendard.title1.weight(.bold))
                    .foregroundColor(.black)
                  if detail.isPicchelin {
                    PickchelinLabel()
                  }
                }
                HStack(spacing: 0) {
                  HStack(spacing: 4) {
                    Image("like-fill")
                      .resizable()
                      .frame(width: 16, height: 16)
                      .foregroundStyle(.brightForsythia)
                    Text("\(detail.pickCount)개").font(.Pretendard.body2).foregroundColor(.g90)
                  }
                  HStack(spacing: 4) {
                    Image("star-fill")
                      .resizable()
                      .frame(width: 16, height: 16)
                      .foregroundStyle(.brightForsythia)
                    Text(String(format: "%.1f", detail.totalRating)).font(.Pretendard.body2)
                      .foregroundColor(
                        .g90)
                    Text("(\(detail.totalReviewCount))").font(.Pretendard.body2).foregroundColor(
                      .g60)
                    Image("chevron")
                      .resizable()
                      .frame(width: 16, height: 16)
                      .foregroundStyle(.g60)
                      .rotationEffect(.degrees(180))
                  }
                  Spacer()
                  HStack(spacing: 4) {
                    Image("order-fill")
                      .resizable()
                      .frame(width: 16, height: 16)
                      .foregroundStyle(.g60)
                    Text("누적 주문 \(detail.totalOrderCount)회")
                      .font(.Pretendard.body2).foregroundColor(.g60)
                  }
                }
              }
              .padding(.horizontal, 20)
              .padding(.top, 20)
              // 정보 카드
              storeInfoCardView(detail: detail)
                .padding(.top, 16)
                .padding(.horizontal, 20)
              // 예상 소요시간/거리
              HStack(spacing: 8) {
                HStack(spacing: 4) {
                  Image("run")
                    .resizable()
                    .frame(width: 20, height: 20)
                  Text("예상 소요시간 \(detail.estimatedPickupTime) (")
                    .font(.Pretendard.caption1)
                  Text(String(format: "%.1fkm", 0.0))
                    .font(.Pretendard.caption1)
                  Text(")")
                    .font(.Pretendard.caption1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                  Capsule()
                    .strokeBorder(Color.g30, lineWidth: 1)
                )
                .background(Color.white)
                .foregroundStyle(.deepSprout)
                Spacer()
              }
              .padding(.horizontal, 20)
              .padding(.top, 8)
              Button(action: {
                // 메뉴 검색 화면으로 이동
              }) {
                Text("길찾기")
                  .font(.Pretendard.title1.weight(.bold))
                  .foregroundStyle(.white)
                  .frame(maxWidth: .infinity)
                  .frame(height: 48)
                  .background(Color.deepSprout)
                  .cornerRadius(12)
              }
              .padding(.top, 12)
              .padding(.horizontal, 20)
            }
            .padding(.bottom, 12)

            // 3. Section(header:)에 카테고리 버튼 그룹을 sticky header로!
            Section(
              header:
                MenuCategoryStickyHeader(
                  categories: categories,
                  onCategorySelected: { category in
                    withAnimation(.easeInOut(duration: 0.35)) {
                      isPressedCategory = category
                      selectedCategory = category
                      proxy.scrollTo(category, anchor: .center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                      withAnimation(.easeInOut(duration: 0.35)) {
                        isPressedCategory = nil
                      }
                    }
                  },
                  selectedCategory: selectedCategory,
                  pressedCategory: isPressedCategory
                )
                .padding(.top, screenTopPadding)
                .background(Color.white)
            ) {
              ForEach(categories, id: \.self) { category in
                if !detail.menuList.filter({ $0.category == category }).isEmpty {
                  MenuCategorySectionView(
                    category: category,
                    menus: detail.menuList.filter { $0.category == category },
                    pressedCategory: isPressedCategory,
                    menuCellProvider: menuCellProvider
                  )
                }
              }
            }
          }
        }
      }
      StickyCartBar(cart: cart, onPay: onCartPay)
    }
  }

  // MARK: - InfoCard/메뉴 셀 (SharedUI로 분리 권장, 여기선 placeholder)
  private func storeInfoCardView(detail: StoreDetail) -> some View {
    VStack(spacing: 8) {
      HStack(alignment: .top) {
        Text("가게주소")
          .font(.Pretendard.body2)
          .foregroundStyle(.g60)
        Image("distance")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundStyle(.deepSprout)
        Text(detail.address ?? "").font(.Pretendard.body2).foregroundStyle(.g60)
        Spacer()
      }
      HStack {
        Text("영업시간")
          .font(.Pretendard.body2)
          .foregroundStyle(.g60)
        Image("time")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundStyle(.deepSprout)
        Text("\(detail.open ?? "정보 없음") ~ \(detail.close ?? "정보 없음")")
          .font(.Pretendard.body2).foregroundStyle(.g60)
        Spacer()
      }
      HStack {
        Text("주차여부")
          .font(.Pretendard.body2)
          .foregroundStyle(.g60)
        Image("parking")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundStyle(.deepSprout)
        Text(detail.parkingGuide ?? "").font(.Pretendard.body2).foregroundStyle(.g60)
        Spacer()
      }
    }
    .padding(16)
    .background(Color.white)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .strokeBorder(Color.g30, lineWidth: 1)
    )

  }

}

// 카테고리별 메뉴 섹션 뷰
struct MenuCategorySectionView: View {
  let category: String
  let menus: [MenuItem]
  let pressedCategory: String?
  let menuCellProvider: (MenuItem) -> MenuCellView

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      let isPressed = pressedCategory == category
      Text(category)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.Pretendard.body1.weight(.bold))
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
          (isPressed ? Color.deepSprout : Color.white)
            .animation(.easeInOut(duration: 0.35), value: isPressed)
        )
        .foregroundColor(isPressed ? .white : .black)
        .padding(.top, 12)
        .background(Color.g15)
        .id(category)
      ForEach(Array(menus.enumerated()), id: \.element.id) { index, menu in
        menuCellProvider(menu)
        if index < menus.count - 1 {
          Divider()
            .padding(.horizontal, 20)
        }
      }
    }
  }
}

struct MenuCellView: View {
  let menu: MenuItem
  let quantity: Int
  @Binding var stepperVisible: Bool
  let onAdd: () -> Void
  let onRemove: () -> Void

  var body: some View {
    let isSoldOut = menu.isSoldOut
    HStack(alignment: .bottom, spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        ForEach(menu.tags, id: \.self) { tag in
          Text(tag)
            .font(.Pretendard.caption2.weight(.semibold))
            .foregroundStyle(.blackSprout)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.brightSprout)
            .cornerRadius(4)
        }
        Text(menu.name)
          .font(.Pretendard.body1.weight(.bold))
          .foregroundColor(.black)
        Text(menu.description)
          .font(.Pretendard.caption1)
          .foregroundColor(.g60)
          .lineLimit(2)
          .frame(height: 40)
        Text("\(menu.price)원")
          .font(.Pretendard.body1.weight(.bold))
          .foregroundColor(.black)
      }
      Spacer()
      if let url = menu.menuImageUrl {
        CachedAsyncImage(url: url) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.gray.opacity(0.1)
        }
        .frame(width: 100, height: 100)
        .overlay(
          ZStack {
            if isSoldOut {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.g90).opacity(0.6)
              Text("품절")
                .font(.Pretendard.body1.weight(.bold))
                .foregroundColor(.white)
            }
            if !isSoldOut {
              ZStack {
                if quantity == 0 {
                  CartButtonView(
                    quantity: quantity,
                    onAdd: onAdd,
                    onRemove: onRemove,
                    stepperVisible: $stepperVisible
                  )
                  .offset(x: 30, y: 30)
                  .transition(.opacity)
                } else if stepperVisible {
                  CartButtonView(
                    quantity: quantity,
                    onAdd: onAdd,
                    onRemove: onRemove,
                    stepperVisible: $stepperVisible
                  )
                  .offset(x: 0, y: 30)
                  .transition(.opacity)
                } else {
                  CartButtonView(
                    quantity: quantity,
                    onAdd: onAdd,
                    onRemove: onRemove,
                    stepperVisible: $stepperVisible
                  )
                  .offset(x: 30, y: 30)
                  .transition(.opacity)
                }
              }
              .animation(.easeInOut(duration: 0.22), value: stepperVisible)
              .animation(.easeInOut(duration: 0.22), value: quantity)
            }
          }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
    .opacity(isSoldOut ? 0.5 : 1.0)
  }
}

// CartButtonView 구현
struct CartButtonView: View {
  let quantity: Int
  let onAdd: () -> Void
  let onRemove: () -> Void
  @Binding var stepperVisible: Bool

  var body: some View {
    if quantity == 0 {
      Button(action: onAdd) {
        ZStack {
          Circle()
            .fill(Color.deepSprout)
            .frame(width: 32, height: 32)
          Image(systemName: "cart")
            .foregroundColor(.white)
            .font(.system(size: 20, weight: .bold))
        }
      }
      .buttonStyle(.plain)
      .shadow(radius: 2, y: 1)
    } else if stepperVisible {
      HStack(spacing: 0) {
        Button(action: onRemove) {
          Image(systemName: "minus")
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .bold))
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        Text("\(quantity)")
          .font(.title3.weight(.bold))
          .frame(width: 32)
          .foregroundColor(.white)
        Button(action: onAdd) {
          Image(systemName: "plus")
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .bold))
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
      }
      .background(
        Capsule()
          .fill(Color.blackSprout)
          .shadow(radius: 2, y: 1)
      )
      .padding(2)
    } else {
      ZStack {
        Circle()
          .fill(Color.deepSprout)
          .frame(width: 32, height: 32)
        Text("\(quantity)")
          .font(.title3.weight(.bold))
          .foregroundColor(.white)
      }
      .shadow(radius: 2, y: 1)
      .onTapGesture {
        // stepperVisible true로 전환 및 3초 타이머 리셋
        stepperVisible = true
        // 타이머 리셋은 Screen에서 관리하므로, onAdd/onRemove에서만 처리됨
        // 필요시, 별도의 onStepperTap 클로저를 추가해 Screen에서 타이머 리셋도 가능
      }
    }
  }
}

struct MenuCategoryStickyHeader: View {
  let categories: [String]
  let onCategorySelected: (String) -> Void
  let selectedCategory: String?
  let pressedCategory: String?

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(categories, id: \.self) { category in
          let isPressed = pressedCategory == category
          Button(action: { onCategorySelected(category) }) {
            Text(category)
              .font(
                selectedCategory == category ? .Pretendard.body2.weight(.bold) : .Pretendard.body2
              )
              .foregroundStyle(selectedCategory == category ? .blackSprout : .g60)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(
                Capsule()
                  .fill(isPressed ? Color.deepSprout : Color.white)
                  .animation(.easeInOut(duration: 0.35), value: isPressed)
                  .overlay(
                    Capsule()
                      .strokeBorder(
                        selectedCategory == category ? .blackSprout : .g30, lineWidth: 1)
                  )
              )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
    }
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

struct ImageCarouselView: View {
  let detail: StoreDetail

  var body: some View {
    TabView {
      ForEach(detail.storeImageUrls, id: \.self) { url in
        CachedAsyncImage(url: url) { image in
          image
            .resizable()
            .scaledToFill()
        } placeholder: {
          Color.gray.opacity(0.1)
        }
        .frame(height: 240)
        .clipped()
      }

    }
    .frame(height: 240)
    .tabViewStyle(.page)
  }
}

// 2. StickyCartBar 구현
struct StickyCartBar: View {
  let cart: Cart?
  let onPay: () -> Void
  var body: some View {
    GeometryReader { geo in
      if let cart = cart, !cart.items.isEmpty {
        let safeArea = geo.safeAreaInsets.bottom
        HStack {
          Text("\(cart.totalPrice)원")
            .font(.Pretendard.title1)
            .foregroundColor(.black)
          Spacer()
          Button(action: onPay) {
            HStack(spacing: 8) {
              Text("결제하기")
                .font(.Pretendard.title1)
              Text("\(cart.items.reduce(0) { $0 + $1.quantity })")
                .font(.Pretendard.caption1)
                .padding(6)
                .foregroundColor(.blackSprout)
                .background(Color.white)
                .clipShape(Circle())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(Color.blackSprout)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: -2)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(Color.g30, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom))
        .animation(.easeInOut, value: cart.items)
      }
    }
    .ignoresSafeArea(edges: .bottom)
    .frame(height: 94)
  }
}

