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
      }
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
}

struct MainHomeView: View {
  // 전달받은 데이터
  let storeList: [StoreInfo]
  let popularStores: [StoreInfo]
  let banners: [BannerInfo]
  let categories: [(name: String, icon: String)]
  let location: String
  let isLoading: Bool
  let errorMessage: String?
  let searchText: String

  // 콜백 함수
  let onSearchTextChanged: (String) -> Void
  let onCategorySelected: (String?) -> Void
  let onLikeToggled: (String) -> Void
  let onLoadMore: () -> Void
  let onLocationSelected: () -> Void

  // 내부 상태
  @State private var selectedCategory: String? = nil
  @State private var searchFocused: Bool = false

  var body: some View {
    ZStack {
      // 메인 콘텐츠
      ScrollView {
        VStack(spacing: 16) {
          LocationView(
            location: location,
            onLocationSelected: onLocationSelected
          )
          SearchView(
            searchText: searchText,
            onSearchTextChanged: onSearchTextChanged
          )
          VStack(spacing: 0) {
            // 카테고리 선택 영역
            CategorySelectView(
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
            if !popularStores.isEmpty {
              StoreListView(
                stores: popularStores,
                onLikeToggled: onLikeToggled
              )
            } else if !storeList.isEmpty {  // 인기 가게가 없을 경우 일반 가게 표시
              StoreListView(
                stores: Array(storeList.prefix(2)),
                onLikeToggled: onLikeToggled
              )
            }

            // 배너 영역
            if !banners.isEmpty {
              BannerView(banner: banners.first!)
                .padding(.horizontal)
            }

            // 내 픽 가게 섹션
            SectionHeaderView(
              title: "내가 픽한 가게",
              trailing: Button(action: {}) {
                HStack {
                  Text("더보기")
                  Image(systemName: "chevron.right")
                }
                .font(.caption)
                .foregroundColor(.gray)
              })

            // 내가 픽한 가게 목록
            MyPickStoreView(selectedFilter: .constant(.pick), onFilterChanged: { _ in })

            // 추가 가게 목록 (세로 리스트)
            LazyVStack(spacing: 8) {
              ForEach(storeList.indices, id: \.self) { index in
                StoreCardView(
                  store: storeList[index],
                  onLikeToggled: { onLikeToggled(storeList[index].store_id) }
                )

                // 마지막 아이템이면 더 로드
                if index == storeList.count - 1 {
                  Color.clear
                    .frame(height: 1)
                    .onAppear {
                      onLoadMore()
                    }
                }
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

      //      // 에러 메시지
      //      if let error = errorMessage, !error.isEmpty {
      //        VStack {
      //          Spacer()
      //          Text(error)
      //            .foregroundColor(.white)
      //            .padding()
      //            .background(Color.red.opacity(0.8))
      //            .cornerRadius(8)
      //            .padding()
      //        }
      //      }
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
        HStack(spacing: 4) {
          Image("location")
            .foregroundStyle(.g90)

          Text(location)
            .foregroundStyle(.g90)
            .font(.pretendardBody1)

          Image("detail")
            .foregroundColor(.gray)
            .font(.caption)
        }
      }

      Spacer()
    }
    .padding(.horizontal)
  }
}

struct SearchView: View {
  let searchText: String
  let onSearchTextChanged: (String) -> Void

  @State private var text: String = ""

  var body: some View {
    VStack(spacing: 10) {
      // 검색창
      HStack(spacing: 8) {
        Image("search")
          .foregroundColor(.gray)

        TextField("검색어를 입력해주세요.", text: $text)
          .font(.subheadline)
          .foregroundColor(.black)
          .onChange(of: text) { newValue in
            onSearchTextChanged(newValue)
          }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 25)
          .fill(Color.white)
          .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
      )
      .padding(.horizontal)

      // 서브텍스트 (인기검색어 등)
      HStack(spacing: 8) {
        Image("ai")
          .resizable()
          .frame(width: 16, height: 16)
          .foregroundStyle(.deepSprout)

        Text("인기검색어")
          .font(.pretendardCaption1)
          .foregroundStyle(.deepSprout)

        Text("1 스타벅스")
          .font(.pretendardCaption1)
          .foregroundStyle(.blackSprout)
        Spacer()
      }
      .padding(.horizontal)
    }
    .padding(.top, 8)
    .onAppear { text = searchText }
  }
}

struct CategorySelectView: View {
  let categories: [(name: String, icon: String)]
  @Binding var selectedCategory: String?
  let onCategorySelected: (String) -> Void

  var body: some View {
    HStack(spacing: 0) {
      ForEach(categories, id: \.name) { category in
        let isSelected = selectedCategory == category.name
        let isDisabled = category.name == "더보기"
        Button(action: {
          if !isDisabled { onCategorySelected(category.name) }
        }) {
          VStack(spacing: 8) {
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.deepSprout : Color.white)
                .frame(width: 60, height: 60)
              Image(category.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .opacity(isDisabled ? 0.3 : 1.0)
            }
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.deepSprout : Color.gray.opacity(0.3), lineWidth: 2)
            )
            Text(category.name)
              .font(.caption)
              .foregroundColor(isDisabled ? .gray : (isSelected ? Color.deepSprout : .gray))
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
}

struct SectionHeaderView: View {
  let title: String
  var trailing: AnyView? = nil

  init(title: String) {
    self.title = title
    self.trailing = nil
  }

  init<T: View>(title: String, trailing: T) {
    self.title = title
    self.trailing = AnyView(trailing)
  }

  var body: some View {
    HStack {
      Text(title)
        .font(.pretendardTitle1)

      Spacer()

      if let trailing = trailing {
        trailing
      }
    }
    .padding(.horizontal)
    .padding(.top, 4)
  }
}

struct StoreListView: View {
  let stores: [StoreInfo]
  let onLikeToggled: (String) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(stores, id: \.store_id) { store in
          StoreCardHorizontalView(
            store: store,
            onLikeToggled: { onLikeToggled(store.store_id) }
          )
          .frame(width: 180, height: 240)
        }
      }
      .padding(.horizontal)
    }
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
          .padding()
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

struct MyPickStoreView: View {
  @Binding var selectedFilter: MyPickFilter
  let onFilterChanged: (MyPickFilter) -> Void

  var body: some View {
    HStack(spacing: 12) {
      ForEach(MyPickFilter.allCases, id: \.self) { filter in
        Button(action: { onFilterChanged(filter) }) {
          HStack(spacing: 4) {
            if filter == .pick {
              Image(systemName: "checkmark.square.fill")
                .foregroundColor(.green)
            }
            Text(filter.title)
              .font(.caption)
              .foregroundColor(selectedFilter == filter ? .black : .gray)
              .fontWeight(.medium)
          }
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(selectedFilter == filter ? Color.white : Color.gray.opacity(0.1))
          .cornerRadius(16)
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(
                selectedFilter == filter ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
          )
        }
      }
      Spacer()
      // 거리순 정렬 버튼 등 추가 가능
    }
    .padding(.horizontal)
  }
}

enum MyPickFilter: String, CaseIterable {
  case pick, myPick
  var title: String {
    switch self {
    case .pick: return "픽 전용"
    case .myPick: return "My Pick"
    }
  }
}

struct StoreCardView: View {
  let store: StoreInfo
  let onLikeToggled: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 가게 이미지 및 정보
      HStack(alignment: .top, spacing: 12) {
        // 메인 이미지
        ZStack(alignment: .topTrailing) {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay(
              CachedAsyncImage(
                url: store.store_image_urls.first ?? "",
                content: { image in
                  image
                    .resizable()
                    .frame(width: 200, height: 100)
                    .aspectRatio(contentMode: .fill)

                },
                placeholder: {
                  Color.gray
                },
                errorView: { error in
                  Text(error.localizedDescription)
                })
            )
            .clipped()

          // 좋아요 버튼
          Button(action: onLikeToggled) {
            Image(systemName: store.is_pick ? "heart.fill" : "heart")
              .foregroundColor(store.is_pick ? .red : .white)
              .font(.system(size: 16))
              .padding(6)
              .background(Circle().fill(Color.black.opacity(0.3)))
          }
          .padding(6)
        }

        // 가게 정보
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(store.name)
                .font(.headline)
                .fontWeight(.bold)

              HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                  .foregroundColor(.orange)
                  .font(.caption)

                Text("\(store.pick_count)개")
                  .font(.caption)
                  .foregroundColor(.gray)

                Image(systemName: "star.fill")
                  .foregroundColor(.orange)
                  .font(.caption)

                Text(String(format: "%.1f", store.total_rating))
                  .font(.caption)
                  .foregroundColor(.gray)

                Text("(\(store.total_review_count))")
                  .font(.caption)
                  .foregroundColor(.gray)
              }
            }

            Spacer()

            // 픽첼린 배지
            if store.is_picchelin {
              Text("픽첼린")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green)
                .cornerRadius(4)
            }
          }

          // 거리, 시간, 주문수 정보
          HStack(spacing: 8) {
            HStack(spacing: 2) {
              Image(systemName: "location.fill")
                .foregroundColor(.gray)
                .font(.caption2)

              Text(String(format: "%.1fkm", store.distance ?? 0))
                .font(.caption)
                .foregroundColor(.gray)
            }

            HStack(spacing: 2) {
              Image(systemName: "clock.fill")
                .foregroundColor(.gray)
                .font(.caption2)

              Text(
                store.close.contains(":")
                  ? "\(store.close.split(separator: ":").first ?? "")PM" : ""
              )
              .font(.caption)
              .foregroundColor(.gray)
            }

            HStack(spacing: 2) {
              Image(systemName: "bag.fill")
                .foregroundColor(.gray)
                .font(.caption2)

              Text("\(store.total_order_count)회")
                .font(.caption)
                .foregroundColor(.gray)
            }
          }

          // 해시태그
          if !store.hashTags.isEmpty {
            HStack(spacing: 6) {
              ForEach(store.hashTags.prefix(2), id: \.self) { tag in
                Text(tag)
                  .font(.caption)
                  .foregroundColor(.gray)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(Color.gray.opacity(0.1))
                  .cornerRadius(12)
              }
            }
          }
        }
      }

      // 하단 추가 이미지들
      HStack(spacing: 8) {
        Spacer()

        ForEach(1..<min(4, store.store_image_urls.count + 1)) { i in
          let imageIndex = min(i, store.store_image_urls.count - 1)
          RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
              Image(store.store_image_urls[imageIndex])
                .resizable()
                .aspectRatio(contentMode: .fill)
            )
            .clipped()
        }
      }
      .padding(.top, 12)
    }
    .padding(16)
    .background(Color.white)
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    .padding(.horizontal)
  }
}

struct StoreCardHorizontalView: View {
  let store: StoreInfo
  let onLikeToggled: () -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .overlay(
          VStack(alignment: .leading, spacing: 8) {
            // 이미지
            CachedAsyncImage(
              url: store.store_image_urls.first ?? "",
              content: { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(height: 100)
                  .clipped()
              }, placeholder: { Color.gray }
            )
            .cornerRadius(12)

            // 정보
            VStack(alignment: .leading, spacing: 4) {
              Text(store.name)
                .font(.headline)
                .lineLimit(1)
              HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                  .foregroundColor(.orange)
                Text("\(store.pick_count)개")
                  .font(.caption)
                  .foregroundColor(.gray)
              }
              // 거리, 시간, 주문수 등
              HStack(spacing: 8) {
                Label(
                  "\(String(format: "%.1fkm", store.distance ?? 0))", systemImage: "location.fill"
                )
                .font(.caption2)
                .foregroundColor(.gray)
                Label("\(store.close)", systemImage: "clock.fill")
                  .font(.caption2)
                  .foregroundColor(.gray)
                Label("\(store.total_order_count)회", systemImage: "bag.fill")
                  .font(.caption2)
                  .foregroundColor(.gray)
              }
            }
            .padding([.horizontal, .bottom], 8)
          }
        )
      // 하트 버튼
      Button(action: onLikeToggled) {
        Image(systemName: store.is_pick ? "heart.fill" : "heart")
          .foregroundColor(store.is_pick ? .red : .white)
          .padding(8)
          .background(Circle().fill(Color.black.opacity(0.3)))
      }
      .padding(8)
    }
    .frame(width: 180, height: 240)
  }
}

extension StoreInfo: Identifiable {
  var id: String { store_id }
}

struct LocationSelectView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var region = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 37.5133, longitude: 126.9269),
    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
  )
  @State private var address: String = "서울 동작구 여의대방로22마길 22"
  @State private var detailAddress: String = "서울 동작구 신대방동 364-9"

  var body: some View {
    VStack(spacing: 0) {
      // 네비게이션 바
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .font(.title3)
            .foregroundColor(.black)
        }
        Spacer()
        Text("지도에서 위치 확인")
          .font(.pretendardTitle1)
          .foregroundColor(.black)
        Spacer().frame(width: 24)  // 좌우 균형
      }
      .padding(.horizontal)
      .padding(.top, 16)
      .padding(.bottom, 8)

      ZStack {
        // 지도
        Map(coordinateRegion: $region, interactionModes: .all)
          .frame(height: 400)
          .clipShape(RoundedRectangle(cornerRadius: 0))
          .edgesIgnoringSafeArea(.horizontal)

        // 중앙 핀
        VStack(spacing: 0) {
          Spacer()
          Image("pin-face")  // 실제 핀 아이콘 리소스 적용
            .resizable()
            .frame(width: 48, height: 48)
            .shadow(radius: 4)
          Spacer().frame(height: 180)
        }
        // 안내 말풍선
        VStack {
          Spacer().frame(height: 180)
          HStack {
            Spacer()
            Text("바꾼 위치가 주소와 같은지 확인해주세요")
              .font(.pretendardBody2)
              .foregroundColor(.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(
                Capsule()
                  .fill(Color.black)
              )
            Spacer()
          }
          Spacer()
        }
      }
      .frame(height: 400)
      .background(Color.gray.opacity(0.05))
      .overlay(
        // 우측 하단 위치 초기화 버튼
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button(action: {
              // 현위치로 이동 로직
            }) {
              Image(systemName: "location.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .background(Circle().fill(Color.black.opacity(0.7)))
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
          }
        }
      )
      Spacer()
      // 하단 시트 스타일
      VStack(spacing: 12) {
        Text(address)
          .font(.pretendardTitle1)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(detailAddress)
          .font(.pretendardBody1)
          .foregroundColor(.gray)
          .frame(maxWidth: .infinity, alignment: .leading)
        Button(action: {
          // 주소 등록 액션
        }) {
          Text("이 위치로 주소 등록")
            .font(.pretendardTitle1)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.deepSprout)
            .cornerRadius(8)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
      .padding(.bottom, 32)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(Color.white)
          .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -2)
      )
    }
    .background(Color.white.ignoresSafeArea())
    .tabBarHidden()
  }
}
