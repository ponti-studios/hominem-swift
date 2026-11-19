import XCTest
@testable import FlightCore
import GeoCore

final class FlightCoreTests: XCTestCase {
    func testAirportCatalogAndFlightDuration() {
        let departure = Date(timeIntervalSince1970: 1_700_000_000)
        let flight = Flight(
            number: "BA117",
            origin: "LHR",
            destination: "JFK",
            departure: departure,
            arrival: departure.addingTimeInterval(28_500)
        )

        XCTAssertEqual(AirportCatalog.coordinate(for: "lhr")?.latitude, 51.4700)
        XCTAssertEqual(flight.originCoordinate?.latitude, 51.4700)
        XCTAssertEqual(flight.destinationCoordinate?.longitude, -73.7781)
        XCTAssertEqual(flight.durationSeconds, 28_500)
    }
}
