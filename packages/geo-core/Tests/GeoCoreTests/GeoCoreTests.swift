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
}
