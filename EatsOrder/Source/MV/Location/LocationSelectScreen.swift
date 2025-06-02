//
//  LocationSelectScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/25/25.
//

import SwiftUI
import MapKit

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
          .font(.Pretendard.title1)
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
              .font(.Pretendard.body2)
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
          .font(.Pretendard.title1)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(detailAddress)
          .font(.Pretendard.body1)
          .foregroundColor(.gray)
          .frame(maxWidth: .infinity, alignment: .leading)
        Button(action: {
          // 주소 등록 액션
        }) {
          Text("이 위치로 주소 등록")
            .font(.Pretendard.body1)
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
    .navigationBarBackButtonHidden(true)
  }
}
