import XCTest

@testable import GeoCore

final class GeoCoreTests: XCTestCase {
  func testCoordinateDistanceAndBearing() {
    let london = GeoCoordinate(latitude: 51.5074, longitude: -0.1278)
    let paris = GeoCoordinate(latitude: 48.8566, longitude: 2.3522)

    XCTAssertGreaterThan(london.distance(to: paris), 340_000)
    XCTAssertLessThan(london.distance(to: paris), 350_000)
    XCTAssertGreaterThanOrEqual(london.bearing(to: paris), 0)
    XCTAssertLessThan(london.bearing(to: paris), 360)
  }

  func testBoundsAndRegion() {
    let points = [
      GeoCoordinate(latitude: 51.5, longitude: -0.2),
      GeoCoordinate(latitude: 51.6, longitude: 0.1),
    ]
    let bounds = GeoBounds(points: points)
    let region = GeoCoordinateRegion.fitting(points)

    XCTAssertNotNil(bounds)
    XCTAssertNotNil(region)
    XCTAssertEqual(bounds?.corners.count, 4)
    XCTAssertEqual(region?.center.latitude ?? 0, 51.55, accuracy: 0.01)
  }

  func testRouteSimplificationKeepsEndpoints() {
    let points = (0...20).map {
      GeoCoordinate(
        latitude: 51.5 + Double($0) * 0.0001,
        longitude: -0.1 + Double($0) * 0.0001
      )
    }
    let simplified = RouteGeometry.simplify(points, toleranceMeters: 1, maxPoints: 480)

    XCTAssertEqual(simplified.first, points.first)
    XCTAssertEqual(simplified.last, points.last)
    XCTAssertLessThanOrEqual(simplified.count, points.count)
  }

  func testDistanceAcrossTheAntimeridianTakesTheShortWay() {
    let east = GeoCoordinate(latitude: 0, longitude: 179.9)
    let west = GeoCoordinate(latitude: 0, longitude: -179.9)

    let distance = east.distance(to: west)

    XCTAssertGreaterThan(distance, 21_000)
    XCTAssertLessThan(distance, 24_000)
  }

  func testRouteLengthAcrossTheAntimeridianIsShort() {
    let route = [
      GeoCoordinate(latitude: 51.5, longitude: 179.95),
      GeoCoordinate(latitude: 51.5, longitude: -179.95),
    ]

    let length = RouteGeometry.length(route)

    XCTAssertGreaterThan(length, 6_000)
    XCTAssertLessThan(length, 8_000)
  }

  func testSimplificationAcrossTheAntimeridianKeepsValidCoordinates() {
    let route =
      (0..<20).map {
        GeoCoordinate(latitude: 51.5, longitude: 179.81 + Double($0) * 0.01)
      }
      + (0..<20).map {
        GeoCoordinate(latitude: 51.51, longitude: -179.9 + Double($0) * 0.01)
      }

    let simplified = RouteGeometry.simplify(route, toleranceMeters: 8, maxPoints: 480)

    XCTAssertEqual(simplified.first, route.first)
    XCTAssertEqual(simplified.last, route.last)
    XCTAssertTrue(simplified.allSatisfy(\.isValid))
  }

  func testPoleToPoleDistanceIsHalfTheCircumference() {
    let northPole = GeoCoordinate(latitude: 90, longitude: 0)
    let southPole = GeoCoordinate(latitude: -90, longitude: 0)

    let distance = northPole.distance(to: southPole)

    XCTAssertGreaterThan(distance, 20_000_000)
    XCTAssertLessThan(distance, 20_015_087)
  }

  func testBearingAtThePoleIsInRange() {
    let northPole = GeoCoordinate(latitude: 90, longitude: 0)
    let london = GeoCoordinate(latitude: 51.5074, longitude: -0.1278)

    let bearing = northPole.bearing(to: london)

    XCTAssertGreaterThanOrEqual(bearing, 0)
    XCTAssertLessThan(bearing, 360)
  }

  func testInvalidCoordinatesAreRejected() {
    let invalid: [GeoCoordinate] = [
      GeoCoordinate(latitude: .nan, longitude: 0),
      GeoCoordinate(latitude: .infinity, longitude: 0),
      GeoCoordinate(latitude: 0, longitude: .nan),
      GeoCoordinate(latitude: 91, longitude: 0),
      GeoCoordinate(latitude: -91, longitude: 0),
      GeoCoordinate(latitude: 0, longitude: 181),
      GeoCoordinate(latitude: 0, longitude: -181),
    ]
    let valid = GeoCoordinate(latitude: 0, longitude: 0)

    XCTAssertTrue(invalid.allSatisfy { !$0.isValid })
    XCTAssertTrue(valid.isValid)
    XCTAssertTrue(GeoCoordinate(latitude: 90, longitude: 180).isValid)
  }

  func testBoundsIgnoresInvalidPointsAndFailsOnEmptyInput() {
    let valid = [
      GeoCoordinate(latitude: 51.5, longitude: -0.2),
      GeoCoordinate(latitude: 51.6, longitude: 0.1),
    ]
    let mixed =
      valid + [
        GeoCoordinate(latitude: .nan, longitude: 0),
        GeoCoordinate(latitude: 999, longitude: 999),
      ]

    XCTAssertNil(GeoBounds(points: []))
    XCTAssertEqual(GeoBounds(points: mixed), GeoBounds(points: valid))
  }

  func testFittingCollapsesToTheMinimumRegionForCoincidentPoints() throws {
    let points = [
      GeoCoordinate(latitude: 51.5074, longitude: -0.1278),
      GeoCoordinate(latitude: 51.50741, longitude: -0.12781),
    ]

    let region = try XCTUnwrap(GeoCoordinateRegion.fitting(points))

    XCTAssertEqual(region.latitudeDelta, 0.004, accuracy: 1e-9)
    XCTAssertEqual(region.longitudeDelta, 0.004 * 1.35, accuracy: 1e-9)
  }

  func testViewportClampsToWorldEdges() {
    let bounds = GeoBounds.viewport(
      center: GeoCoordinate(latitude: 90, longitude: 180),
      latitudeDelta: 1,
      longitudeDelta: 1
    )

    XCTAssertEqual(bounds.maxLatitude, 90)
    XCTAssertEqual(bounds.maxLongitude, 180)
    XCTAssertGreaterThan(bounds.minLongitude, 179)
  }

  func testAntipodalGreatCircleFallsBackToEndpoints() {
    let equatorial = GeoCoordinate(latitude: 0, longitude: 0)
      .greatCircle(to: GeoCoordinate(latitude: 0, longitude: 180), steps: 48)
    let oblique = GeoCoordinate(latitude: 51.5, longitude: 0)
      .greatCircle(to: GeoCoordinate(latitude: -51.5, longitude: 180), steps: 48)

    XCTAssertEqual(
      equatorial,
      [
        GeoCoordinate(latitude: 0, longitude: 0),
        GeoCoordinate(latitude: 0, longitude: 180),
      ])
    XCTAssertEqual(
      oblique,
      [
        GeoCoordinate(latitude: 51.5, longitude: 0),
        GeoCoordinate(latitude: -51.5, longitude: 180),
      ])
  }

  func testGreatCircleIsSymmetricAndShortNearTheAntimeridian() {
    let east = GeoCoordinate(latitude: 0, longitude: 179.9)
    let west = GeoCoordinate(latitude: 0, longitude: -179.9)

    let arc = east.greatCircle(to: west, steps: 4)

    XCTAssertEqual(arc.count, 5)
    XCTAssertTrue(arc.allSatisfy(\.isValid))
    XCTAssertTrue(
      arc.dropFirst().dropLast().allSatisfy { point in
        abs(point.longitude) > 170
      })
  }

  func testSimplificationIsDeterministic() {
    let route = (0..<200).map { index -> GeoCoordinate in
      let step = Double(index)
      return GeoCoordinate(
        latitude: 51.5 + sin(step / 9) * 0.002,
        longitude: -0.1 + step * 0.0002
      )
    }

    let first = RouteGeometry.simplify(route)
    let second = RouteGeometry.simplify(route)

    XCTAssertEqual(first, second)
  }

  func testSimplificationRespectsMaximumPointCount() {
    let route = (0..<600).map { index -> GeoCoordinate in
      let step = Double(index)
      return GeoCoordinate(
        latitude: 51.5 + sin(step / 7) * 0.004,
        longitude: -0.1 + step * 0.00006
      )
    }

    let simplified = RouteGeometry.simplify(route, toleranceMeters: 8, maxPoints: 10)

    XCTAssertLessThanOrEqual(simplified.count, 10)
    XCTAssertEqual(simplified.first, route.first)
    XCTAssertEqual(simplified.last, route.last)
  }

  func testEmptyAndSinglePointRoutes() {
    let single = [GeoCoordinate(latitude: 51.5, longitude: -0.1)]

    XCTAssertEqual(RouteGeometry.simplify([]), [])
    XCTAssertEqual(RouteGeometry.simplify(single), single)
    XCTAssertEqual(RouteGeometry.length([]), 0)
    XCTAssertEqual(RouteGeometry.length(single), 0)
    XCTAssertNil(GeoBounds(points: []))
    XCTAssertNil(GeoCoordinateRegion.fitting([]))
    XCTAssertNil(GeoCoordinateRegion.fitting([GeoCoordinate(latitude: .nan, longitude: 0)]))
  }
}
