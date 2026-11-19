import CoreLocation
import Foundation

public struct GeoCoordinate: Codable, Hashable, Sendable {
  public var latitude: Double
  public var longitude: Double

  public init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }

  public init(_ coordinate: CLLocationCoordinate2D) {
    self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }

  public init(_ coordinate: GeoCoordinate) {
    self.init(
      latitude: coordinate.latitude,
      longitude: coordinate.longitude
    )
  }

  public var isValid: Bool {
    latitude.isFinite
      && longitude.isFinite
      && (-90...90).contains(latitude)
      && (-180...180).contains(longitude)
  }

  public var clLocationCoordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  public var coordinate: CLLocationCoordinate2D {
    clLocationCoordinate
  }

  public func distance(to other: GeoCoordinate) -> Double {
    let earthRadius = 6_371_000.0
    let lat1 = latitude * .pi / 180
    let lat2 = other.latitude * .pi / 180
    let deltaLat = (other.latitude - latitude) * .pi / 180
    let deltaLon = (other.longitude - longitude) * .pi / 180
    let a =
      sin(deltaLat / 2) * sin(deltaLat / 2)
      + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
  }

  public func bearing(to other: GeoCoordinate) -> Double {
    let lat1 = latitude * .pi / 180
    let lat2 = other.latitude * .pi / 180
    let deltaLon = (other.longitude - longitude) * .pi / 180
    let y = sin(deltaLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
    return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
  }

  public func greatCircle(to other: GeoCoordinate, steps: Int = 48) -> [GeoCoordinate] {
    guard isValid, other.isValid else { return [self, other] }
    let count = max(2, steps)
    let lat1 = latitude * .pi / 180
    let lon1 = longitude * .pi / 180
    let lat2 = other.latitude * .pi / 180
    let lon2 = other.longitude * .pi / 180
    let distance =
      2
      * asin(
        sqrt(
          pow(sin((lat2 - lat1) / 2), 2)
            + cos(lat1) * cos(lat2) * pow(sin((lon2 - lon1) / 2), 2)
        ))
    guard distance > 1e-9 else { return [self, other] }
    guard distance < .pi - 1e-6 else { return [self, other] }

    return (0...count).map { index in
      let fraction = Double(index) / Double(count)
      let a = sin((1 - fraction) * distance) / sin(distance)
      let b = sin(fraction * distance) / sin(distance)
      let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
      let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
      let z = a * sin(lat1) + b * sin(lat2)
      let lat = atan2(z, sqrt(x * x + y * y))
      let lon = atan2(y, x)
      return GeoCoordinate(latitude: lat * 180 / .pi, longitude: lon * 180 / .pi)
    }
  }
}
