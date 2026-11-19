import XCTest
@testable import TransitCore
import GeoCore

final class TransitCoreTests: XCTestCase {
    func testTfLPayloadParsing() throws {
        let json = """
        [{
          "id": "JamCams_ABC",
          "commonName": "Test Junction",
          "lat": 51.5,
          "lon": -0.1,
          "additionalProperties": [
            {"key": "view", "value": "North"},
            {"key": "available", "value": "true"},
            {"key": "imageUrl", "value": "https://example.com/camera.jpg"}
          ]
        }]
        """.data(using: .utf8)!

        let cameras = try TFLJamCamClient.parse(json)
        XCTAssertEqual(cameras.count, 1)
        XCTAssertEqual(cameras.first?.name, "Test Junction")
        XCTAssertEqual(cameras.first?.coordinate.latitude, 51.5)
    }
}
