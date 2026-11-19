import XCTest
import CoreData
import GeoCore
@testable import WalksCore

private extension WalkRouteSummary {
    func withBounds(_ route: WalkRoute) -> WalkRouteSummary {
        let coordinates = route.locations.map {
            GeoCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
        return WalkRouteSummary(
            id: id,
            startDate: startDate,
            endDate: endDate,
            hasGPSRoute: hasGPSRoute,
            title: title,
            activity: activity,
            bounds: GeoBounds(points: coordinates),
            pointCount: coordinates.count,
            distanceMeters: RouteGeometry.length(coordinates)
        )
    }
}

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

    func testFloat32CoordinateSnapshotRoundTrip() throws {
        let route = WalkRoute(
            id: UUID(),
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_000_060),
            locations: [
                RouteLocation(latitude: 51.5, longitude: -0.12, elevation: 10, timestamp: Date(timeIntervalSince1970: 1_700_000_000)),
                RouteLocation(latitude: 51.51, longitude: -0.11, elevation: 11, timestamp: Date(timeIntervalSince1970: 1_700_000_060)),
            ]
        )

        let decoded = try JSONDecoder().decode(
            WalkRoute.self,
            from: JSONEncoder().encode(route)
        )

        XCTAssertEqual(decoded.id, route.id)
        XCTAssertEqual(decoded.locations.count, 2)
        XCTAssertEqual(decoded.locations.first?.latitude ?? 0, 51.5, accuracy: 0.0001)
        XCTAssertEqual(decoded.locations.last?.longitude ?? 0, -0.11, accuracy: 0.0001)
        XCTAssertEqual(decoded.locations.first?.elevation, nil, "Float32 snapshots drop elevation")
        XCTAssertEqual(
            decoded.locations.last?.timestamp.timeIntervalSince1970 ?? 0,
            1_700_000_060,
            accuracy: 0.001
        )
    }

    func testLegacyLocationsArrayDecodes() throws {
        // Pre-snapshot archives stored a plain locations array.
        let legacy = """
        {"id":"11111111-1111-1111-1111-111111111111",
         "startDate":721692800.0,"endDate":721692860.0,
         "locations":[
           {"latitude":51.5,"longitude":-0.12,"elevation":10,"timestamp":721692800.0},
           {"latitude":51.51,"longitude":-0.11,"elevation":11,"timestamp":721692860.0}]}
        """

        let decoded = try JSONDecoder().decode(WalkRoute.self, from: Data(legacy.utf8))

        XCTAssertEqual(decoded.id.uuidString, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(decoded.locations.count, 2)
        XCTAssertEqual(decoded.locations.first?.latitude ?? 0, 51.5, accuracy: 1e-12)
        XCTAssertEqual(decoded.locations.first?.elevation, 10, "Legacy arrays keep elevation")
    }

    func testHealthArchiveMergeSkipsShortWorkoutsAndSortsNewestFirst() {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_700_000_060)
        let older = UUID()
        let workouts = [
            HealthWorkout(
                id: id,
                start: start,
                end: end,
                activity: "walking",
                locations: [
                    RouteLocation(latitude: 51.5, longitude: -0.12, elevation: nil, timestamp: start),
                    RouteLocation(latitude: 51.51, longitude: -0.11, elevation: nil, timestamp: end),
                ]
            ),
            HealthWorkout(
                id: older,
                start: start.addingTimeInterval(-3_600),
                end: start.addingTimeInterval(-3_540),
                activity: "walking",
                locations: [
                    RouteLocation(latitude: 51.4, longitude: -0.12, elevation: nil, timestamp: start),
                    RouteLocation(latitude: 51.41, longitude: -0.11, elevation: nil, timestamp: end),
                ]
            ),
            HealthWorkout(
                id: UUID(),
                start: start,
                end: end,
                activity: "walking",
                locations: [
                    RouteLocation(latitude: 51.5, longitude: -0.12, elevation: nil, timestamp: start)
                ]
            ),
        ]

        let merged = HealthWalkArchive.merging(workouts, into: HealthWalkArchive())

        XCTAssertEqual(merged.walks.count, 2, "One-point workouts are skipped")
        XCTAssertEqual(merged.walks.first?.id, id, "Newest walk sorts first")
        XCTAssertEqual(merged.walks.first?.pointCount, 2)
        XCTAssertNotNil(merged.walks.first?.bounds)
        XCTAssertGreaterThan(merged.walks.first?.distanceMeters ?? 0, 1_000)
    }

    func testHealthArchiveNormalizationFillsMissingBoundsAndDropsRoutelessWalks() throws {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_700_000_060)
        let route = WalkRoute(
            id: id,
            startDate: start,
            endDate: end,
            locations: [
                RouteLocation(latitude: 51.5, longitude: -0.12, elevation: nil, timestamp: start),
                RouteLocation(latitude: 51.51, longitude: -0.11, elevation: nil, timestamp: end),
            ]
        )
        let withNilBounds = WalkRouteSummary(
            id: id,
            startDate: start,
            endDate: end,
            hasGPSRoute: true
        )
        let routeless = WalkRouteSummary(
            id: UUID(),
            startDate: start,
            endDate: end,
            hasGPSRoute: true
        )

        let repaired = try XCTUnwrap(HealthWalkArchive(
            walks: [withNilBounds, routeless],
            routes: [route]
        ).normalized())
        XCTAssertEqual(repaired.walks.count, 1)
        XCTAssertEqual(repaired.walks.first?.bounds?.minLatitude ?? 0, 51.5, accuracy: 1e-9)
        XCTAssertEqual(repaired.routes.count, 1)

        let clean = HealthWalkArchive(
            walks: [withNilBounds.withBounds(route)],
            routes: [route]
        )
        XCTAssertNil(clean.normalized(), "An already-normalized archive changes nothing")
    }

    @MainActor
    func testCloudKitIsDisabledUnderXCTest() {
        let identifier = "iCloud.test.container"

        XCTAssertNil(WalkStore.resolvedCloudKitContainerIdentifier(
            configured: identifier,
            arguments: [],
            environment: ["XCTestConfigurationFilePath": "/tmp/config"]
        ))
        XCTAssertNil(WalkStore.resolvedCloudKitContainerIdentifier(
            configured: identifier,
            arguments: [],
            environment: ["WALKSGPX_DISABLE_CLOUDKIT": "1"]
        ))
        XCTAssertNil(WalkStore.resolvedCloudKitContainerIdentifier(
            configured: identifier,
            arguments: ["--walksgpx-disable-cloudkit"],
            environment: [:]
        ))
        XCTAssertEqual(
            WalkStore.resolvedCloudKitContainerIdentifier(
                configured: identifier,
                arguments: [],
                environment: [:]
            ),
            identifier
        )
    }

    @MainActor
    func testStoreDescriptionKeepsCloudKitOffInMemoryStores() {
        let inMemory = WalkStore.makePersistentStoreDescription(
            storeURL: nil,
            inMemory: true,
            cloudKitContainerIdentifier: "iCloud.test.container"
        )
        let sqlite = WalkStore.makePersistentStoreDescription(
            storeURL: URL(fileURLWithPath: "/tmp/walks-test.sqlite"),
            inMemory: false,
            cloudKitContainerIdentifier: "iCloud.test.container"
        )
        let plainSQLite = WalkStore.makePersistentStoreDescription(
            storeURL: URL(fileURLWithPath: "/tmp/walks-test.sqlite"),
            inMemory: false,
            cloudKitContainerIdentifier: nil
        )

        XCTAssertEqual(inMemory.type, NSInMemoryStoreType)
        XCTAssertNil(inMemory.cloudKitContainerOptions)
        XCTAssertEqual(sqlite.type, NSSQLiteStoreType)
        XCTAssertEqual(sqlite.cloudKitContainerOptions?.databaseScope, .private)
        XCTAssertNil(plainSQLite.cloudKitContainerOptions)
    }

    @MainActor
    func testInMemoryStoreSavesAndFetchesRoutes() async throws {
        let store = WalkStore(inMemory: true)
        await store.waitUntilReady()
        XCTAssertNil(store.loadError)

        let route = WalkRoute(
            id: UUID(),
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_000_060),
            locations: [
                RouteLocation(latitude: 51.5, longitude: -0.12, elevation: 10, timestamp: Date(timeIntervalSince1970: 1_700_000_000)),
                RouteLocation(latitude: 51.51, longitude: -0.11, elevation: 11, timestamp: Date(timeIntervalSince1970: 1_700_000_060)),
            ]
        )

        try store.save([route])
        let fetched = try XCTUnwrap(store.fetchRoutes().first)

        XCTAssertEqual(fetched.id, route.id)
        XCTAssertEqual(fetched.locations.count, 2)
        XCTAssertEqual(fetched.locations.first?.latitude ?? 0, 51.5, accuracy: 1e-12)
        XCTAssertEqual(fetched.locations.first?.elevation, 10, "Store keeps the legacy array form")
    }

    func testICloudReconcileWritesRoutesDeletesStaleFilesAndWritesManifest() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("walks-reconcile-\(UUID().uuidString)")
        let publisher = ICloudWalkPublisher(
            configuration: WalkArchiveConfiguration(
                containerIdentifier: "iCloud.test.container",
                userVisibleFolderName: "Walks"
            ),
            folderOverride: folder
        )
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let stale = folder.appendingPathComponent("walk-stale.gpx")
        try Data("stale".utf8).write(to: stale)
        let note = folder.appendingPathComponent("notes.txt")
        try Data("keep me".utf8).write(to: note)

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_700_000_060)
        let route = WalkRoute(
            id: UUID(),
            startDate: start,
            endDate: end,
            locations: [
                RouteLocation(latitude: 51.5, longitude: -0.12, elevation: 10, timestamp: start),
                RouteLocation(latitude: 51.51, longitude: -0.11, elevation: 11, timestamp: end),
            ]
        )

        let report = try await publisher.reconcile(routes: [route])

        XCTAssertEqual(report.routeCount, 1)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: stale.path),
            "Reconcile deletes GPX files the manifest no longer lists"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: note.path),
            "Reconcile leaves non-GPX files untouched"
        )
        let manifest = try WalkExportManifest.decode(
            try Data(contentsOf: folder.appendingPathComponent("manifest.json"))
        )
        XCTAssertEqual(manifest.walks.count, 1)
        let filename = try XCTUnwrap(manifest.walks.first?.filename)
        let document = try XCTUnwrap(GPXParser.parse(data: try Data(
            contentsOf: folder.appendingPathComponent(filename)
        )))
        XCTAssertEqual(document.locations.count, 2)

        try? FileManager.default.removeItem(at: folder)
    }

    func testRouteBatchAccumulatorFinishesAllSeries() {
        let accumulator = RouteBatchAccumulator<String>(routeSeriesCount: 2)
        XCTAssertFalse(accumulator.append(["a"], completed: true).finished)
        let result = accumulator.append(["b"], completed: true)
        XCTAssertTrue(result.finished)
        XCTAssertEqual(result.locations, ["a", "b"])
    }
}
