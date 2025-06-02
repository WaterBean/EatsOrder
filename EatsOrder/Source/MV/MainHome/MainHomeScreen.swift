//
//  MainHomeScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/21/25.
//

import Combine
import MapKit
import SwiftUI

struct MainHomeScreen: View {
  @EnvironmentObject var storeModel: StoreModel
  @EnvironmentObject var locationManager: LocationManager
  @Environment(\.navigate) private var navigate
  @Environment(\.isTabBarHidden) private var isTabBarHidden
  @State private var selectedCategory: String? = nil
  @State private var myPickSort: MyPickSort = .latest
  @State private var filterPickchelin: Bool = false
  @State private var filterMyPick: Bool = false

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
    MainHomeView(
      storeList: storeModel.storeList,
      popularStores: storeModel.popularStores,
      banners: storeModel.banners,
      categories: Category.allCases.map { ($0.rawValue, $0.icon) },
      location: storeModel.location,
      isLoading: storeModel.isLoading,
      errorMessage: storeModel.error,
      searchText: storeModel.searchText,
      onSearchTextChanged: { text in
        storeModel.dispatch(.setSearchText(text: text))
      },
      onCategorySelected: { category in
        Task {
          await storeModel.filterByCategory(category)
        }
      },
      onLikeToggled: { storeId in
        storeModel.dispatch(.toggleStoreLike(storeId: storeId))
      },
      onLoadMore: {
        Task {
          await storeModel.loadMoreStores()
        }
      },
      onLocationSelected: {
        navigate(.push(HomeRoute.locationSelect))
      },
      onStoreDetailSelected: { storeId in
        navigate(.push(HomeRoute.storeDetail(storeId: storeId)))
      },
      myPickSort: $myPickSort,
      filterPickchelin: $filterPickchelin,
      filterMyPick: $filterMyPick,
      filteredAndSortedStores: filteredAndSortedStores
    )
    .background(.brightSprout)
    .toolbar(.hidden, for: .navigationBar)

    .task {
      // 위치 정보 있으면 바로 로드, 없으면 위치 요청
      if let coordinates = locationManager.getCurrentCoordinates() {
        await storeModel.loadInitialData(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude
        )
      } else {
        do {
          let locationData = try await locationManager.requestLocation()
          await storeModel.loadInitialData(
            latitude: locationData.latitude,
            longitude: locationData.longitude
          )
        } catch {
          // 위치 정보 없이 기본 좌표로 로드 (문래역 근처로 가정)
          await storeModel.loadInitialData(latitude: 37.517, longitude: 126.886)
        }
      }
    }
  }

  // 필터/정렬 적용 함수
  var filteredAndSortedStores: [Store] {
    var result = storeModel.storeList
    // 필터
    if filterPickchelin && filterMyPick {
      result = result.filter { $0.isPicchelin && $0.isPick }
    } else if filterPickchelin {
      result = result.filter { $0.isPicchelin }
    } else if filterMyPick {
      result = result.filter { $0.isPick }
    }
    // 둘 다 해제면 전체
    // 정렬
    switch myPickSort {
    case .latest:
      return result.sorted {
        ($0.createdAt.toDate() ?? Date.distantPast) > ($1.createdAt.toDate() ?? Date.distantPast)
      }
    case .distance:
      return result.sorted {
        ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude)
      }
    case .rating:
      return result.sorted { $0.totalRating > $1.totalRating }
    }
  }
}

struct MainHomeView: View {
  // 전달받은 데이터
  let storeList: [Store]
  let popularStores: [Store]
  let banners: [BannerInfo]
  let categories: [(name: String, icon: String)]
  let location: String
  let isLoading: Bool
  let errorMessage: String?
  let searchText: String
  let onSearchTextChanged: (String) -> Void
  let onCategorySelected: (String?) -> Void
  let onLikeToggled: (String) -> Void
  let onLoadMore: () -> Void
  let onLocationSelected: () -> Void
  let onStoreDetailSelected: (String) -> Void
  // 상태를 Binding으로 전달
  @Binding var myPickSort: MyPickSort
  @Binding var filterPickchelin: Bool
  @Binding var filterMyPick: Bool
  let filteredAndSortedStores: [Store]

  // 내부 상태
  @State private var selectedCategory: String? = nil
  @State private var searchFocused: Bool = false

  var body: some View {
    ZStack {
      // 메인 콘텐츠
      ScrollView {
        VStack(spacing: 0) {
          LocationView(
            location: location,
            onLocationSelected: onLocationSelected
          )
          SearchBarView(
            searchText: searchText,
            onSearchTextChanged: onSearchTextChanged
          )
          popularSearchTermsView()
          VStack(spacing: 0) {
            // 카테고리 선택 영역
            categorySelectView(
              categories: categories,
              selectedCategory: $selectedCategory,
              onCategorySelected: { category in
                if selectedCategory == category {
                  selectedCategory = nil
                  onCategorySelected(nil)
                } else {
                  selectedCategory = category
                  onCategorySelected(category)
                }
              }
            )

            // 실시간 인기 맛집 섹션
            SectionHeaderView(title: "실시간 인기 맛집")

            // 인기 맛집 목록 (가로 스크롤)
            PopularStoresListView(
              stores: popularStores,
              onLikeToggled: onLikeToggled,
              onStoreDetailSelected: onStoreDetailSelected
            )

            // 배너 영역
            // BannerView(banner: banners.first ?? BannerInfo(id: "", imageUrl: "", title: "", badgeText: ""))
            //     .padding(.horizontal)

            // 내 픽 가게 섹션
            SectionHeaderView(
              title: "내가 픽한 가게",
              trailing:
                HStack(spacing: 8) {
                  ForEach(MyPickSort.allCases, id: \.self) { sort in
                    Button(action: { myPickSort = sort }) {
                      Text(sort.title)
                        .font(.caption)
                        .foregroundColor(myPickSort == sort ? .deepSprout : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                          myPickSort == sort ? Color.brightSprout.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(12)
                    }
                  }
                }
            )

            // 필터 토글 버튼 그룹 (체크박스)
            HStack(spacing: 12) {
              Toggle(isOn: $filterPickchelin) {
                HStack(spacing: 4) {
                  Image(systemName: filterPickchelin ? "checkmark.square.fill" : "square")
                    .foregroundColor(filterPickchelin ? .deepSprout : .g60)
                  Text("픽슐랭")
                    .font(.Pretendard.body3.weight(.medium))
                    .foregroundColor(filterPickchelin ? .deepSprout : .g60)
                }
              }
              .toggleStyle(.button)
              .buttonStyle(.plain)

              Toggle(isOn: $filterMyPick) {
                HStack(spacing: 4) {
                  Image(systemName: filterMyPick ? "checkmark.square.fill" : "square")
                    .foregroundColor(filterMyPick ? .deepSprout : .g60)
                  Text("My Pick")
                    .font(.Pretendard.body3.weight(.medium))
                    .foregroundColor(filterMyPick ? .deepSprout : .g60)
                }
              }
              .toggleStyle(.button)
              .buttonStyle(.plain)
              Spacer()
            }
            .padding(.horizontal)

            // 리스트 렌더링 (필터/정렬 적용)
            ForEach(filteredAndSortedStores, id: \.id) { store in
              StoreListCellView(store: store, onLikeToggled: { onLikeToggled(store.id) }
              )
              .onTapGesture {
                onStoreDetailSelected(store.id)
              }
            }
          }
          .background(.g0)
          .clipShape(RoundedRectangle(cornerRadius: 20))
          .padding(.bottom, 80)  // 탭바 영역 고려
        }
        .background(.brightSprout)
        .ignoresSafeArea(.all)
      }
      // 로딩 인디케이터
      if isLoading {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(1.5)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.black.opacity(0.2))
      }

    }
  }

  private func popularSearchTermsView() -> some View {

    HStack(spacing: 8) {
      Image("ai")
        .resizable()
        .frame(width: 16, height: 16)
        .foregroundStyle(.deepSprout)

      Text("인기검색어")
        .font(.Pretendard.caption1)
        .foregroundStyle(.deepSprout)

      Text("1 스타벅스")
        .font(.Pretendard.caption1)
        .foregroundStyle(.blackSprout)
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 12)

  }

  private func categorySelectView(
    categories: [(name: String, icon: String)],
    selectedCategory: Binding<String?>,
    onCategorySelected: @escaping (String) -> Void
  ) -> some View {
    HStack(spacing: 0) {
      ForEach(categories, id: \.name) { category in
        let isSelected = selectedCategory.wrappedValue == category.name
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

struct BannerView: View {
  let banner: BannerInfo

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      RoundedRectangle(cornerRadius: 12)
        .fill(
          LinearGradient(
            gradient: Gradient(colors: [Color("BannerStart"), Color("BannerEnd")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(height: 120)
        .overlay(
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(banner.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
              Text("픽업하면 0원")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            Image(banner.imageUrl)  // 실제 일러스트 이미지
              .resizable()
              .frame(width: 60, height: 60)
          }

        )
      // 뱃지/진행도
      HStack(spacing: 8) {
        Text(banner.badgeText)
          .font(.caption)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.green)
          .cornerRadius(12)
        Text("1/12")
          .font(.caption)
          .foregroundColor(.white)
      }
      .padding()
    }
  }
}


struct PopularStoresListView: View {
  let stores: [Store]
  let onLikeToggled: (String) -> Void
  let onStoreDetailSelected: (String) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(stores, id: \.id) { store in
          popularShopItemView(
            store: store,
            onLikeToggled: { onLikeToggled(store.id) }
          )
          .onTapGesture {
                onStoreDetailSelected(store.id)
          }
        }
      }
      .padding([.horizontal, .bottom], 20)
    }
  }

  private func popularShopItemView(store: Store, onLikeToggled: @escaping () -> Void)
    -> some View
  {
    VStack(spacing: 0) {
      header(
        isLiked: store.isPick,
        onLikeToggled: onLikeToggled
      )
      Spacer()
      infoView(store: store)
        .frame(height: 56)
    }
    .frame(width: 240, height: 176)
    .background(
      CachedAsyncImage(
        url: store.storeImageurls.first ?? "",
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
  private func header(
    isLiked: Bool,
    onLikeToggled: @escaping () -> Void
  ) -> some View {
    HStack {
      likeButton(isLiked: isLiked, onLikeToggled: onLikeToggled)
      Spacer()
      PickchelinLabel()
    }
    .padding(.horizontal, 12)
  }

  private func likeButton(isLiked: Bool, onLikeToggled: @escaping () -> Void) -> some View {
    Button(action: onLikeToggled) {
      Image(isLiked ? "like-fill" : "like-empty")
        .foregroundColor(isLiked ? .blackSprout : .g30)
        .padding(8)
    }
  }

  private func infoView(store: Store) -> some View {
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
        Text("\(store.distance ?? 0)km")
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

enum MyPickSort: String, CaseIterable {
  case latest = "최신순"
  case distance = "거리순"
  case rating = "평점순"
  var title: String { rawValue }
}

struct PickchelinLabel: View {
  var body: some View {
    ZStack(alignment: .leading) {
      Image("pickchelin-tag")
      HStack(spacing: 4) {
        Image("pick-fill")
          .resizable()
          .frame(width: 12, height: 12)
          .foregroundColor(.white)
        Text("픽슐랭")
          .font(.Pretendard.caption2)
          .foregroundColor(.white)
      }
      .padding([.vertical, .leading], 4)
    }
  }
}
