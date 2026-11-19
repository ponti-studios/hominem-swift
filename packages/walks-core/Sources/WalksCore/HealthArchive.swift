import Foundation
import GeoCore

public struct HealthWorkout: Sendable, Equatable {
  public let id: UUID
  public let start: Date
  public let end: Date
  public let activity: String?
  public let locations: [RouteLocation]

  public init(
    id: UUID,
    start: Date,
    end: Date,
    activity: String?,
    locations: [RouteLocation]
  ) {
    self.id = id
    self.start = start
    self.end = end
    self.activity = activity
    self.locations = locations
  }
}

public struct HealthWalkArchive: Codable, Sendable, Equatable {
  public var version: Int
  public var lastSyncedAt: Date?
  public var walks: [WalkRouteSummary]
  public var routes: [WalkRoute]

  public init(
    version: Int = 1,
    lastSyncedAt: Date? = nil,
    walks: [WalkRouteSummary] = [],
    routes: [WalkRoute] = []
  ) {
    self.version = version
    self.lastSyncedAt = lastSyncedAt
    self.walks = walks
    self.routes = routes
  }

  public var fileName: String { "health-walks.json" }

  public static func url(beside snapshot: URL) -> URL {
    snapshot.deletingLastPathComponent().appendingPathComponent("atlas-health.json")
  }

  public static func load(from url: URL) -> HealthWalkArchive {
    guard let raw = try? Data(contentsOf: url) else { return HealthWalkArchive() }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let archive = try? decoder.decode(HealthWalkArchive.self, from: raw) else {
      return HealthWalkArchive()
    }
    return archive
  }

  public func write(to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let payload = try encoder.encode(self)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try payload.write(to: url, options: [.atomic])
  }

  public static func hasRoute(_ locations: [RouteLocation]) -> Bool {
    locations.count > 1
  }

  public static func merging(
    _ workouts: [HealthWorkout],
    into archive: HealthWalkArchive,
    syncedAt: Date = .now
  ) -> HealthWalkArchive {
    var walks = Dictionary(
      archive.walks.map { ($0.id, $0) },
      uniquingKeysWith: { first, _ in first }
    )
    var routes = Dictionary(
      archive.routes.map { ($0.id, $0) },
      uniquingKeysWith: { first, _ in first }
    )

    for workout in workouts {
      let points = workout.locations
      guard hasRoute(points) else { continue }
      let coordinates = points.map {
        GeoCoordinate(latitude: $0.latitude, longitude: $0.longitude)
      }
      guard let bounds = GeoBounds(points: coordinates) else { continue }
      walks[workout.id] = WalkRouteSummary(
        id: workout.id,
        startDate: workout.start,
        endDate: workout.end,
        hasGPSRoute: true,
        activity: workout.activity,
        bounds: bounds,
        pointCount: points.count,
        distanceMeters: RouteGeometry.length(coordinates)
      )
      routes[workout.id] = WalkRoute(
        id: workout.id,
        startDate: workout.start,
        endDate: workout.end,
        locations: points
      )
    }

    return HealthWalkArchive(
      version: archive.version,
      lastSyncedAt: syncedAt,
      walks: walks.values.sorted { $0.startDate > $1.startDate },
      routes: routes.values.sorted { $0.startDate > $1.startDate }
    )
  }

  public func normalized() -> HealthWalkArchive? {
    let routesByID = Dictionary(
      routes.map { ($0.id, $0) },
      uniquingKeysWith: { first, _ in first }
    )
    var kept: [WalkRouteSummary] = []
    var changed = false

    for walk in walks {
      guard walk.hasGPSRoute, let route = routesByID[walk.id] else {
        changed = true
        continue
      }
      let coordinates = route.locations.map {
        GeoCoordinate(latitude: $0.latitude, longitude: $0.longitude)
      }
      guard let bounds = GeoBounds(points: coordinates) else {
        changed = true
        continue
      }
      if walk.bounds == nil {
        changed = true
        kept.append(
          WalkRouteSummary(
            id: walk.id,
            startDate: walk.startDate,
            endDate: walk.endDate,
            hasGPSRoute: true,
            title: walk.title,
            activity: walk.activity,
            bounds: bounds,
            pointCount: coordinates.count,
            distanceMeters: RouteGeometry.length(coordinates)
          ))
      } else {
        kept.append(walk)
      }
    }

    guard changed else { return nil }
    let keptIDs = Set(kept.map(\.id))
    return HealthWalkArchive(
      version: version,
      lastSyncedAt: lastSyncedAt,
      walks: kept,
      routes: routes.filter { keptIDs.contains($0.id) }
    )
  }
}
