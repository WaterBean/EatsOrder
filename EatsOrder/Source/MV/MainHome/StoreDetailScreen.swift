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
  @EnvironmentObject private var model: StoreModel
  @Environment(\.dismiss) private var dismiss
  @State private var storeDetail = StoreDetail(
    storeId: "", category: "", name: "", description: "", hashTags: [], open: "", close: "",
    address: "", estimatedPickupTime: 0, parkingGuide: "", storeImageUrls: [], isPicchelin: false,
    isPick: false, pickCount: 0, totalReviewCount: 0, totalOrderCount: 0, totalRating: 0,
    creator: Creator(userId: "", nick: "", profileImage: ""), geolocation: GeoLocation(
      longitude: 0, latitude: 0), menuList: [], createdAt: "", updatedAt: "")

  var body: some View {
    StoreDetailView(
      detail: storeDetail, onBack: { dismiss() },
      onLikeToggled: {
        // 좋아요 토글 로직 (API 연동 필요)
      }
    )
    .task { storeDetail = await model.fetchDetail(storeId: storeId) }
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
  @State private var scrollY: CGFloat = 0
  @State private var selectedCategory: String? = nil
  @State private var isHeaderPressed: Bool = false
  @State private var isPressedCategory: String? = nil

  var categories: [String] {
    let all = detail.menuList.map { $0.category }
    return Array(NSOrderedSet(array: all)) as? [String] ?? []
  }

  var body: some View {
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
              Button(action: onLikeToggled) {
                Image(detail.isPick ? "like-fill" : "like-empty")
                  .foregroundColor(detail.isPick ? .blackSprout : .white)
                  .padding(12)
                  .background(Color.black.opacity(0.3))
                  .clipShape(Circle())
              }
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
                  Text("(\(detail.totalReviewCount))").font(.Pretendard.body2).foregroundColor(.g60)
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
                  // 0.35초 후 원상복귀
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
                  pressedCategory: isPressedCategory
                )
              }
            }
          }
        }
      }
    }
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
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

// 메뉴 전체 섹션 리스트 뷰
struct MenuSectionListView: View {
  let categories: [String]
  let menus: [MenuItem]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(categories, id: \.self) { category in
        let menusForCategory = menus.filter { $0.category == category }
        MenuCategorySectionView(category: category, menus: menusForCategory, pressedCategory: nil)
      }
    }
  }
}

// 카테고리별 메뉴 섹션 뷰
struct MenuCategorySectionView: View {
  let category: String
  let menus: [MenuItem]
  let pressedCategory: String?

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
        MenuCellView(menu: menu)
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
  var body: some View {

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
            if menu.isSoldOut {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.g90).opacity(0.6)
              Text("품절")
                .font(.Pretendard.body1.weight(.bold))
                .foregroundColor(.white)
            }
          }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }

    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }
}

private struct OffsetKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
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
