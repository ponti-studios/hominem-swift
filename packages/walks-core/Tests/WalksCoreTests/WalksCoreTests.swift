import XCTest
@testable import WalksCore

final class WalksCoreTests: XCTestCase {
    func testGPXExportAndParseRoundTrip() throws {
        let route = WalkRoute(
            id: UUID(),
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_000_060),
            locations: [
                RouteLocation(latitude: 51.5, longitude: -0.12, elevation: 10, timestamp: Date(timeIntervalSince1970: 1_700_000_000)),
                RouteLocation(latitude: 51.51, longitude: -0.11, elevation: 11, timestamp: Date(timeIntervalSince1970: 1_700_000_060)),
            ]
        )

        let document = try XCTUnwrap(GPXParser.parse(data: GPXExporter.data(for: route)))
        XCTAssertEqual(document.locations.count, 2)
        let latitude = try XCTUnwrap(document.locations.first?.latitude)
        XCTAssertEqual(latitude, 51.5, accuracy: 0.0001)
    }

    func testManifestDeduplicatesAndSortsRoutes() throws {
        let early = Date(timeIntervalSince1970: 100)
        let late = Date(timeIntervalSince1970: 200)
        let id = UUID()
        let routes = [
            WalkRoute(id: id, startDate: late, endDate: late, locations: []),
            WalkRoute(id: id, startDate: late, endDate: late, locations: []),
            WalkRoute(id: UUID(), startDate: early, endDate: early, locations: []),
        ]

        let manifest = WalkExportManifest(routes: routes)
        XCTAssertEqual(manifest.walks.count, 2)
        XCTAssertEqual(manifest.walks.first?.startDate, early)

        let encoded = try WalkExportManifest.encode(manifest)
        let decoded = try WalkExportManifest.decode(encoded)
        XCTAssertEqual(decoded.schemaVersion, manifest.schemaVersion)
        XCTAssertEqual(decoded.walks, manifest.walks)
    }

    func testSyncCheckpointQueuesAndAcknowledgesExports() {
        var checkpoint = WalkSyncCheckpoint()
        let routeID = UUID()

        checkpoint.queueExport(for: [routeID])
        XCTAssertTrue(checkpoint.pendingExportRouteIDs.contains(routeID))

        checkpoint.acknowledgeExport(for: [routeID])
        XCTAssertFalse(checkpoint.pendingExportRouteIDs.contains(routeID))
    }

    func testRouteBatchAccumulatorFinishesAllSeries() {
        let accumulator = RouteBatchAccumulator<String>(routeSeriesCount: 2)
        XCTAssertFalse(accumulator.append(["a"], completed: true).finished)
        let result = accumulator.append(["b"], completed: true)
        XCTAssertTrue(result.finished)
        XCTAssertEqual(result.locations, ["a", "b"])
    }
}
