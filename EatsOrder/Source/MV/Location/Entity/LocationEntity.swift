//
//  LocationEntity.swift
//  EatsOrder
//
//  Created by 한수빈 on 2025/06/03.
//

import CoreLocation
import Foundation

// 위치 정보 모델
struct GeoLocation: Entity {
  let longitude: Double
  let latitude: Double

  var horizontalAccuracy: Double {
    50
  }

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  init(longitude: Double, latitude: Double) {
    self.longitude = longitude
    self.latitude = latitude
  }

  init(coordinate: CLLocationCoordinate2D) {
    self.longitude = coordinate.longitude
    self.latitude = coordinate.latitude
  }

  init(coordinate: CLLocationCoordinate2D, address: String) {
    self.longitude = coordinate.longitude
    self.latitude = coordinate.latitude
  }

  var id: String {
    "\(longitude)-\(latitude)"
  }
}

struct Location: Entity {
  let id: String
  let nickname: String
  let fullAddress: String
  let geoLocation: GeoLocation

  init(nickname: String, fullAddress: String, geoLocation: GeoLocation) {
    self.nickname = nickname
    self.fullAddress = fullAddress
    self.geoLocation = geoLocation
    self.id = "\(geoLocation.longitude)-\(geoLocation.latitude)-\(nickname)"
  }
}
