//
//  StoreListCellView.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/05/27.
//

import SwiftUI

struct StoreListCellView: View {
  let store: StoreInfo
  let onLikeToggled: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 4) {
        // 메인 이미지
        ZStack(alignment: .topLeading) {
          Rectangle()
            .fill(Color.gray.opacity(0.08))
            .overlay(
              CachedAsyncImage(
                url: store.storeImageUrls.first ?? "",
                content: { image in
                  image
                    .resizable()
                    .scaledToFill()
                },
                placeholder: { Color.gray.opacity(0.1) },
                errorView: { error in Text(error.localizedDescription) }
              )
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))

          HStack {
            // 좋아요 버튼
            Button(action: onLikeToggled) {
              Image(store.isPick ? "like-fill" : "like-empty")
                .foregroundColor(store.isPick ? .blackSprout : .white)
                .font(.system(size: 18, weight: .bold))
            }
            .frame(width: 32, height: 32)
            Spacer()
            if store.isPicchelin {
              PickchelinLabel()
            }
          }
          .padding(8)
          .padding(.leading, 8)
        }

        if store.storeImageUrls.count > 1 {
          VStack(spacing: 4) {
            ForEach(1..<min(4, store.storeImageUrls.count), id: \.self) { i in
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.08))
                .overlay(
                  CachedAsyncImage(
                    url: store.storeImageUrls[i],
                    content: { image in
                      image
                        .resizable()
                        .aspectRatio(1.268, contentMode: .fill)

                    },
                    placeholder: { Color.gray.opacity(0.1) },
                    errorView: { error in Text(error.localizedDescription) }
                  )
                )
                .frame(width: 78, height: 61.5)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
          }
        }
      }
      .padding(.bottom, 16)
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .center, spacing: 6) {
          Text(store.name)
            .font(.Pretendard.body1.weight(.bold))
            .foregroundColor(.black)
            .lineLimit(1)
          statsView(store: store)
        }
        infoView(store: store)
        hashtagView(store: store)
      }
      Divider()
        .padding(.top, 12)
    }
    .backgroundStyle(.g15)
    .padding(.horizontal, 20)
    .padding(.vertical, 6)
  }

  private func statsView(store: StoreInfo) -> some View {
    HStack(spacing: 8) {
      HStack(spacing: 2) {
        Image("like-fill")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundStyle(.brightForsythia)
        Text("\(store.pickCount)개")
          .font(.Pretendard.body1.weight(.bold))
          .foregroundStyle(.g90)
      }
      HStack(spacing: 2) {
        Image("star-fill")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundColor(.brightForsythia)
        Text(String(format: "%.1f", store.totalRating))
          .font(.Pretendard.body1.weight(.bold))
          .foregroundStyle(.g90)
        Text("(\(store.totalReviewCount))")
          .font(.Pretendard.body1)
          .foregroundStyle(.g60)
      }
    }
  }

  private func infoView(store: StoreInfo) -> some View {
    HStack(spacing: 10) {
      HStack(spacing: 2) {
        Image("distance")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundColor(.blackSprout)
        Text(String(format: "%.1fkm", store.geolocation.longitude))
          .font(.Pretendard.body2)
          .foregroundColor(.g60)
      }
      HStack(spacing: 2) {
        Image("time")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundColor(.blackSprout)
        Text(store.close)
          .font(.Pretendard.body2)
          .foregroundColor(.g60)
      }
      HStack(spacing: 2) {
        Image("run")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundColor(.blackSprout)
        Text("\(store.totalOrderCount)회")
          .font(.Pretendard.body2)
          .foregroundColor(.g60)
      }
    }
  }

  private func hashtagView(store: StoreInfo) -> some View {
    Group {
      if !store.hashTags.isEmpty {
        HStack(spacing: 6) {
          ForEach(store.hashTags.prefix(2), id: \.self) { tag in
            Text(tag)
              .font(.Pretendard.caption1.weight(.semibold))
              .foregroundColor(.white)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(Color.deepSprout)
              .cornerRadius(4)
          }
        }
      }
    }
  }
}
