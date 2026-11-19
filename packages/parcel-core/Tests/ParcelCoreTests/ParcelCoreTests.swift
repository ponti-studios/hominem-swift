import XCTest
@testable import ParcelCore
import GeoCore

final class ParcelCoreTests: XCTestCase {
    func testParcelRoundTrip() throws {
        let parcel = Parcel(
            trackingNumber: "1Z999",
            carrier: "UPS",
            status: "In transit",
            lastLocation: GeoCoordinate(latitude: 51.5, longitude: -0.1)
        )
        let data = try JSONEncoder().encode(parcel)
        let decoded = try JSONDecoder().decode(Parcel.self, from: data)

        XCTAssertEqual(decoded, parcel)
    }
}
