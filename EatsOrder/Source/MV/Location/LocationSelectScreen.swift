//
//  LocationSelectScreen.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/25/25.
//

import Combine
import MapKit
import SwiftUI

struct LocationSelectScreen: View {
  @EnvironmentObject var locationModel: LocationModel
  @Environment(\.dismiss) private var dismiss

  @State private var isDragging: Bool = false
  @State private var showNicknameAlert: Bool = false
  @State private var nicknameInput: String = ""
  @State private var showNicknameError: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      headerView()
      ZStack {
        locationSelectMap(
          region: $locationModel.region, currentLocation: locationModel.currentLocation
        )
        .gesture(
          DragGesture()
            .onChanged { _ in isDragging = true }
            .onEnded { _ in isDragging = false }
        )
        mapCenterMarker()
          .allowsHitTesting(false)
        // 내 위치로 이동 버튼 (오른쪽 하단)
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button(action: moveToCurrentLocation) {
              Image(systemName: "location.fill")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundColor(.blue)
                .padding(16)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
          }
        }
        .allowsHitTesting(true)
      }
      .frame(height: 400)
      .background(Color.gray.opacity(0.05))
      .onAppear {
        locationModel.startRegionDebounce()
      }
      .onDisappear {
        locationModel.cancelRegionDebounce()
      }
      Spacer()
      infoView()
    }
    .background(Color.white.ignoresSafeArea())
    .tabBarHidden()
    .navigationBarBackButtonHidden(true)
  }

  private func headerView() -> some View {
    HStack {
      Button(action: { dismiss() }) {
        Image("chevron")
          .resizable()
          .frame(width: 24, height: 24)
          .foregroundColor(.black)
      }
      Text("내 위치 설정하기")
        .font(.Pretendard.title1)
        .foregroundColor(.black)
      Spacer()
    }
    .padding(.horizontal)
    .padding(.top, 16)
    .padding(.bottom, 8)
  }

  private func locationSelectMap(region: Binding<MKCoordinateRegion>, currentLocation: GeoLocation?)
    -> some View
  {
    Map(
      coordinateRegion: region,
      annotationItems: currentLocation.map { [$0.coordinate] } ?? []
    ) { coordinate in
      MapAnnotation(coordinate: coordinate) {
        ZStack {
          LocationAccuracyCircle(accuracy: currentLocation?.horizontalAccuracy)
          Image("location")
            .resizable()
            .frame(width: 32, height: 32)
            .foregroundColor(.blackSprout)
            .shadow(radius: 4)
        }
      }
    }
  }

  private func infoView() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(locationModel.address)
        .font(.Pretendard.title1)
        .foregroundColor(.black)
      if !locationModel.detail.isEmpty {
        Text(locationModel.detail)
          .font(.Pretendard.body2)
          .foregroundColor(.gray)
      }
      Button(action: {
        showNicknameAlert = true
      }) {
        Text("설정하기")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
      .padding(.top, 12)
    }
    .padding(.horizontal)
    .padding(.vertical, 20)
    .background(Color.white)
    .alert("주소 별명 입력", isPresented: $showNicknameAlert) {
      TextField("예: 우리집, 회사", text: $nicknameInput)
      Button("저장") {
        if nicknameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          showNicknameError = true
        } else if let geo = locationModel.currentLocation {
          locationModel.saveRecentLocation(
            nickname: nicknameInput,
            fullAddress: locationModel.address,
            geoLocation: geo
          )
          dismiss()
        }
      }
      Button("취소", role: .cancel) {}
    } message: {
      if showNicknameError {
        Text("별명을 입력해주세요.")
      }
    }
  }

  private func mapCenterMarker() -> some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Image("location")
          .resizable()
          .frame(width: 32, height: 32)
          .shadow(radius: 4)
          .offset(y: -16)
        Spacer()
      }
      Spacer()
    }
  }

  private func moveToCurrentLocation() {
    if let loc = locationModel.currentLocation {
      locationModel.region.center = loc.coordinate
    }
  }
}

struct LocationAccuracyCircle: View {
  let accuracy: Double?
  var body: some View {
    if let accuracy {
      let circleSize = max(40, min(accuracy, 200))
      Circle()
        .fill(Color.blue.opacity(0.15))
        .frame(width: circleSize, height: circleSize)
    }
  }
}
