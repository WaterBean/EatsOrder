//
//  StoreExploreScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import SwiftUI
import EOCore

struct StoreExploreScreen: View {
  @EnvironmentObject var storeModel: StoreModel
  @EnvironmentObject var locationModel: LocationModel
  @EnvironmentObject var authModel: AuthModel
  @Environment(\.navigate) private var navigate
  @Environment(\.isTabBarHidden) private var isTabBarHidden

  // 상태: Screen에서만 소유
  @State private var selectedCategory: String? = nil
  @State private var nextCursor: String = ""
  @State private var isLoadingMore: Bool = false
  @State private var isEndReached: Bool = false
  @State private var isInitialLoading: Bool = false
  @State private var errorMessage: String? = nil
  @State private var paginationTrigger: Bool = false
  @State private var popularSearches: [String] = []
  @State private var currentSearchIndex = 0
  @State private var timer: Timer? = nil
  @State private var didLoad = false

  // 카테고리 정의
  enum Category: String, CaseIterable {
    case coffee = "커피"
    case fastfood = "패스트푸드"
    case dessert = "디저트"
    case bakery = "베이커리"
    case more = "더보기"
    var icon: String {
      switch self {
      case .coffee: return "coffee"
      case .fastfood: return "fastfood"
      case .dessert: return "dessert"
      case .bakery: return "bakery"
      case .more: return "more"
      }
    }
  }

  var body: some View {
    ZStack {
      ScrollView {
        VStack(spacing: 0) {
          LocationView(
            location: locationModel.recentLocation.nickname,
            onLocationSelected: { navigate(.push(HomeRoute.locationSelect)) }
          )
          SearchBarView(
            searchText: storeModel.searchText,
            onSearchTextChanged: { text in
              storeModel.dispatch(.setSearchText(text: text))
            }
          )
          popularSearchTermsView(popularSearches: popularSearches)
          VStack(spacing: 0) {
            categorySelectView(
              categories: Category.allCases.map { ($0.rawValue, $0.icon) },
              selectedCategory: storeModel.selectedCategory,
              onCategorySelected: { category in
                if storeModel.selectedCategory == category {
                  storeModel.selectedCategory = nil
                } else {
                  storeModel.selectedCategory = category
                }
              }
            )
            SectionHeaderView(title: "실시간 인기 맛집")
            Group {
              if storeModel.selectedCategory != nil, storeModel.filteredPopularStores.isEmpty {
                VStack {
                  Spacer()
                  Text("해당하는 가게가 없습니다")
                    .font(.Pretendard.body1)
                    .foregroundStyle(.g60)
                  Spacer()
                }
                .frame(minHeight: 196)
              } else {
                PopularStoresListView(
                  stores: storeModel.filteredPopularStores,
                  onStoreDetailSelected: { storeId in
                    navigate(.push(HomeRoute.storeDetail(storeId: storeId)))
                  },
                  onLikeToggled: { store in
                    try await storeModel.toggleStoreLike(
                      storeId: store.id, currentLikeStatus: store.isPick)
                  }
                )
              }
            }
            SectionHeaderView(
              title: "내 주변 가게",
              trailing:
                HStack(spacing: 8) {
                  ForEach(NearbySort.allCases, id: \.self) { sort in
                    Button(action: { storeModel.nearbySort = sort }) {
                      Text(sort.title)
                        .font(.caption)
                        .foregroundColor(storeModel.nearbySort == sort ? .deepSprout : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                          storeModel.nearbySort == sort
                            ? Color.brightSprout.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(12)
                    }
                  }
                }
            )
            HStack(spacing: 12) {
              Toggle(isOn: $storeModel.filterPicchelin) {
                HStack(spacing: 4) {
                  Image(systemName: storeModel.filterPicchelin ? "checkmark.square.fill" : "square")
                    .foregroundColor(storeModel.filterPicchelin ? .deepSprout : .g60)
                  Text("픽슐랭")
                    .font(.Pretendard.body3.weight(.medium))
                    .foregroundColor(storeModel.filterPicchelin ? .deepSprout : .g60)
                }
              }
              .toggleStyle(.button)
              .buttonStyle(.plain)
              Toggle(isOn: $storeModel.filterMyPick) {
                HStack(spacing: 4) {
                  Image(systemName: storeModel.filterMyPick ? "checkmark.square.fill" : "square")
                    .foregroundColor(storeModel.filterMyPick ? .deepSprout : .g60)
                  Text("My Pick")
                    .font(.Pretendard.body3.weight(.medium))
                    .foregroundColor(storeModel.filterMyPick ? .deepSprout : .g60)
                }
              }
              .toggleStyle(.button)
              .buttonStyle(.plain)
              Spacer()
            }
            .padding(.horizontal)
            storeListSection(stores: storeModel.filteredAndSortedNearbyStores)
            GeometryReader { geo in
              Color.clear
                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).maxY)
            }
            .frame(height: 0)
          }
          .background(.g0)
          .clipShape(RoundedRectangle(cornerRadius: 20))
          .padding(.bottom, 80)
        }
        .ignoresSafeArea(.all)
      }
      .onPreferenceChange(ScrollOffsetPreferenceKey.self) { maxY in
        print("onPreferenceChange called, maxY: \(maxY)")
        // 하단 근처(200pt 이내)에서만 트리거
        if maxY < screenHeight + 400, !isLoadingMore, !isEndReached,
          !storeModel.nearbyStores.isEmpty
        {
          Task { await loadMoreNearbyStores() }
        }
      }
    }

    .task {
      guard !didLoad else { return }
      didLoad = true
      isInitialLoading = true
      locationModel.startUpdatingLocation()
      storeModel.popularStores = await storeModel.fetchPopularStores(category: nil)
      popularSearches = await storeModel.fetchPopularSearches()
      await reloadNearbyStores()
      isInitialLoading = false
    }
    .onChange(of: locationModel.recentLocation) { _ in
      Task { await reloadNearbyStores() }
    }
    .onChange(of: authModel.isLoggedIn) { isLoggedIn in
      if isLoggedIn {
        Task {
          storeModel.popularStores = await storeModel.fetchPopularStores(category: nil)
          popularSearches = await storeModel.fetchPopularSearches()
          await reloadNearbyStores()
        }
      }
    }
  }

  // 내 주변 가게 페이지네이션 및 초기화 함수
  func reloadNearbyStores() async {
    isLoadingMore = true
    isEndReached = false
    nextCursor = ""
    errorMessage = nil
    let (stores, cursor) = await storeModel.fetchNearbyStores(
      latitude: locationModel.recentLocation.geoLocation.coordinate.latitude,
      longitude: locationModel.recentLocation.geoLocation.coordinate.longitude,
      maxDistance: 3000,
      next: "",
      limit: 10,
      orderBy: "distance"
    )
    await MainActor.run {
      storeModel.nearbyStores = stores
    }
    nextCursor = cursor
    isEndReached = (cursor == "0")
    isLoadingMore = false
  }

  func loadMoreNearbyStores() async {
    guard !isLoadingMore, !isEndReached else { return }
    isLoadingMore = true
    let (stores, cursor) = await storeModel.fetchNearbyStores(
      latitude: locationModel.recentLocation.geoLocation.coordinate.latitude,
      longitude: locationModel.recentLocation.geoLocation.coordinate.longitude,
      maxDistance: 3000,
      next: nextCursor,
      limit: 10,
      orderBy: "distance"
    )
    // 중복 id 제거 후 append
    let newStores = stores.filter { new in
      !storeModel.nearbyStores.contains(where: { $0.id == new.id })
    }
    await MainActor.run {
      storeModel.nearbyStores.append(contentsOf: newStores)
    }
    nextCursor = cursor
    isEndReached = (cursor == "0")
    isLoadingMore = false
  }

  
  // 검색어
  private func popularSearchTermsView(popularSearches: [String]) -> some View {
    HStack(spacing: 8) {
      Image("ai")
        .resizable()
        .frame(width: 16, height: 16)
        .foregroundStyle(.deepSprout)
      Text("인기검색어")
        .font(.Pretendard.caption1)
        .foregroundStyle(.deepSprout)
      Text(
        popularSearches.isEmpty
          ? "" : "\(currentSearchIndex + 1)  \(popularSearches[currentSearchIndex])"
      )
      .font(.Pretendard.caption1)
      .foregroundStyle(.blackSprout)
      .animation(.easeInOut, value: currentSearchIndex)
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 12)
    .onAppear {
      if !popularSearches.isEmpty {
        startPopularSearchTimer()
      }
    }
    .onDisappear {
      stopPopularSearchTimer()
    }
    .onChange(of: popularSearches) { newValue in
      if !newValue.isEmpty {
        currentSearchIndex = 0
        startPopularSearchTimer()
      } else {
        stopPopularSearchTimer()
      }
    }
  }

  private func startPopularSearchTimer() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
      withAnimation {
        if !popularSearches.isEmpty {
          currentSearchIndex = (currentSearchIndex + 1) % popularSearches.count
        }
      }
    }
  }

  private func stopPopularSearchTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func categorySelectView(
    categories: [(name: String, icon: String)],
    selectedCategory: String?,
    onCategorySelected: @escaping (String) -> Void
  ) -> some View {
    HStack(spacing: 0) {
      ForEach(categories, id: \.name) { category in
        let isSelected = selectedCategory == category.name
        Button(action: {
          onCategorySelected(category.name)
        }) {
          VStack(spacing: 8) {
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 60, height: 60)
              Image(category.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            }
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .blackSprout : .g30, lineWidth: isSelected ? 1.5 : 1)
            )
            Text(category.name)
              .font(
                isSelected ? .Pretendard.body3.weight(.bold) : .Pretendard.body3.weight(.medium)
              )
              .foregroundColor(isSelected ? Color.blackSprout : .g60)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(20)
  }

  @ViewBuilder
  private func storeListSection(stores: [StoreInfo]) -> some View {
    if stores.isEmpty {
      VStack(spacing: 16) {
        Image("empty-store")
          .resizable()
          .scaledToFit()
          .frame(width: 120, height: 120)
        Text("주변에 가게가 없어요")
          .font(.Pretendard.body1)
          .foregroundStyle(.g60)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 40)
    } else {
      ForEach(stores, id: \.id) { store in
        StoreListCellView(
          store: store,
          onLikeToggled: {
            Task {
              try? await storeModel.toggleStoreLike(
                storeId: store.id, currentLikeStatus: store.isPick)
            }
          }
        )
        .onTapGesture {
          navigate(.push(HomeRoute.storeDetail(storeId: store.id)))
        }
      }
    }
  }
}

// MARK: - 하위 컴포넌트

struct LocationView: View {
  let location: String
  let onLocationSelected: () -> Void

  var body: some View {
    HStack {
      Button(action: onLocationSelected) {
        HStack(spacing: 8) {
          Image("location")
            .resizable()
            .frame(width: 24, height: 24)

          Text(location)
            .font(.Pretendard.body1.weight(.bold))

          Image("detail")
        }
        .foregroundColor(.g90)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 20)
  }
}

struct PopularStoresListView: View {
  let stores: [StoreInfo]
  let onStoreDetailSelected: (String) -> Void
  let onLikeToggled: (StoreInfo) async throws -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(stores, id: \.id) { store in
          popularShopItemView(store: store)
            .onTapGesture {
              onStoreDetailSelected(store.id)
            }
        }
      }
      .padding([.horizontal, .bottom], 20)
    }
  }

  private func popularShopItemView(store: StoreInfo) -> some View {
    VStack(spacing: 0) {
      header(store: store)
      Spacer()
      infoView(store: store)
        .frame(height: 56)
    }
    .frame(width: 240, height: 176)
    .background(
      CachedAsyncImage(
        url: store.storeImageUrls.first ?? "",
        content: { image in
          image
            .resizable()
            .scaledToFill()
        },
        placeholder: {
          Color.gray
        },
        errorView: { error in
          Text(error.localizedDescription)
        }
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
  }

  private func header(store: StoreInfo) -> some View {
    HStack {
      LikeButton(
        isLiked: store.isPick,
        size: 20,
        padding: 8,
        likedColor: .blackSprout,
        unlikedColor: .white
      ) {
        try await onLikeToggled(store)
      }
      Spacer()
      if store.isPicchelin {
        PickchelinLabel()
      }
    }
    .padding(.horizontal, 12)
  }

  private func infoView(store: StoreInfo) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        Text(store.name)
          .font(.Pretendard.body1.weight(.bold))
          .foregroundColor(.black)
          .lineLimit(1)
          .padding(.leading, 10)
        HStack(spacing: 4) {
          Image("like-fill")
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundColor(.brightForsythia)
          Text("\(store.pickCount)개")
            .font(.Pretendard.body3.weight(.bold))
            .foregroundColor(.g90)
        }
        Spacer()
      }

      HStack(spacing: 6) {
        Image("distance")
          .resizable()
          .frame(width: 16, height: 16)
          .padding(.leading, 10)
          .foregroundColor(.blackSprout)
        Text(String(format: "%.1fkm", store.geolocation.longitude/100))
          .font(.Pretendard.body3)
          .foregroundColor(.g75)
        Image("time")
          .resizable()
          .frame(width: 16, height: 16)
          .foregroundColor(.blackSprout)
        Text(store.close)
          .font(.Pretendard.body3)
          .foregroundColor(.g75)
        Image("run")
          .resizable()
          .frame(width: 16, height: 16)
          .foregroundColor(.blackSprout)
        Text("\(store.totalOrderCount)회")
          .font(.Pretendard.body3)
          .foregroundColor(.g75)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .background(Color.white)
  }
}

enum NearbySort: String, CaseIterable {
  case distance = "거리순"
  case orders = "주문수"
  case reviews = "리뷰수"
  var title: String { rawValue }
}


struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
