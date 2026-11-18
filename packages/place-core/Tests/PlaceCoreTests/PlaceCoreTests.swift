import XCTest
@testable import PlaceCore

final class PlaceCoreTests: XCTestCase {
    func testResultIdentityIsStableAtNearbyCoordinates() {
        let first = PlaceSearchResult(
            name: "Blue Bottle",
            address: "1 Test Street",
            category: "cafe",
            coordinate: PlaceCoordinate(latitude: 51.5000001, longitude: -0.1000001)
        )
        let second = PlaceSearchResult(
            name: "Blue Bottle",
            address: "1 Test Street",
            category: "cafe",
            coordinate: PlaceCoordinate(latitude: 51.5000002, longitude: -0.1000002)
        )

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.coordinate.latitude, 51.5, accuracy: 0.00001)
    }

    func testDifferentPlacesHaveDifferentIdentity() {
        let first = PlaceSearchResult(
            name: "Blue Bottle",
            address: "",
            category: "",
            coordinate: PlaceCoordinate(latitude: 51.5, longitude: -0.1)
        )
        let second = PlaceSearchResult(
            name: "Blue Bottle",
            address: "",
            category: "",
            coordinate: PlaceCoordinate(latitude: 51.6, longitude: -0.1)
        )

        XCTAssertNotEqual(first.id, second.id)
    }

    func testSearchErrorsHaveReadableDescriptions() {
        XCTAssertEqual(
            PlaceSearchError.emptyQuery.localizedDescription,
            "Type something to search for."
        )
        XCTAssertEqual(
            PlaceSearchError.noResults.localizedDescription,
            "Apple Maps found no matches."
        )
    }
}
