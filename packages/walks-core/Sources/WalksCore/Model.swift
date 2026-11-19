import Foundation
import GeoCore
import CoreLocation

// MARK: - Route model (pure, no UI, no device deps)

public struct WalkRoute: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let locations: [RouteLocation]

    public init(id: UUID, startDate: Date, endDate: Date, locations: [RouteLocation]) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.locations = locations
    }

    public var durationSeconds: TimeInterval { max(0, endDate.timeIntervalSince(startDate)) }
    public var duration: String {
        let minutes = max(1, Int(endDate.timeIntervalSince(startDate) / 60))
        return "\(minutes) min"
    }
    public var filename: String { Self.filename(for: startDate) }

    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case coordinates
        case locations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        if let blob = try? container.decode(Data.self, forKey: .coordinates) {
            locations = Self.decodeCoordinates(blob, startDate: startDate, endDate: endDate)
        } else {
            locations = try container.decode([RouteLocation].self, forKey: .locations)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(Self.encodeCoordinates(locations), forKey: .coordinates)
    }

    private static func encodeCoordinates(_ locations: [RouteLocation]) -> Data {
        var data = Data(capacity: locations.count * 8)
        for location in locations {
            var pair = (
                Float32(location.latitude).bitPattern.littleEndian,
                Float32(location.longitude).bitPattern.littleEndian
            )
            withUnsafeBytes(of: &pair) { data.append(contentsOf: $0) }
        }
        return data
    }

    private static func decodeCoordinates(
        _ data: Data,
        startDate: Date,
        endDate: Date
    ) -> [RouteLocation] {
        let count = data.count / 8
        guard count > 0 else { return [] }
        let step = count > 1
            ? endDate.timeIntervalSince(startDate) / Double(count - 1)
            : 0

        var locations: [RouteLocation] = []
        locations.reserveCapacity(count)
        data.withUnsafeBytes { raw in
            for index in 0..<count {
                let latitudeBits = raw.loadUnaligned(
                    fromByteOffset: index * 8,
                    as: UInt32.self
                )
                let longitudeBits = raw.loadUnaligned(
                    fromByteOffset: index * 8 + 4,
                    as: UInt32.self
                )
                locations.append(RouteLocation(
                    latitude: Double(Float32(bitPattern: UInt32(littleEndian: latitudeBits))),
                    longitude: Double(Float32(bitPattern: UInt32(littleEndian: longitudeBits))),
                    elevation: nil,
                    timestamp: startDate.addingTimeInterval(step * Double(index))
                ))
            }
        }
        return locations
    }

    public static func filename(for startDate: Date) -> String {
        "walk-\(filenameDate.string(from: startDate)).gpx"
    }

    private static let filenameDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

public struct RouteLocation: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double?
    public let timestamp: Date

    public init(latitude: Double, longitude: Double, elevation: Double?, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timestamp = timestamp
    }

    public var isValidGPXPoint: Bool {
        latitude.isFinite && longitude.isFinite &&
            (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct WalkRouteSummary: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let hasGPSRoute: Bool
    public let title: String?
    public let activity: String?
    public let bounds: GeoBounds?
    public let pointCount: Int?
    public let distanceMeters: Double?

    public init(
        id: UUID,
        startDate: Date,
        endDate: Date,
        hasGPSRoute: Bool,
        title: String? = nil,
        activity: String? = nil,
        bounds: GeoBounds? = nil,
        pointCount: Int? = nil,
        distanceMeters: Double? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.hasGPSRoute = hasGPSRoute
        self.title = title
        self.activity = activity
        self.bounds = bounds
        self.pointCount = pointCount
        self.distanceMeters = distanceMeters
    }

    public var durationSeconds: TimeInterval { max(0, endDate.timeIntervalSince(startDate)) }
    public var filename: String { WalkRoute.filename(for: startDate) }
}

public struct WalkSearchFilter: Equatable, Sendable, Codable {
    public var startDate: Date?
    public var endDate: Date?
    public var minimumDuration: TimeInterval?
    public var maximumDuration: TimeInterval?
    public var requiresGPSRoute: Bool?

    public init(startDate: Date? = nil, endDate: Date? = nil,
                minimumDuration: TimeInterval? = nil, maximumDuration: TimeInterval? = nil,
                requiresGPSRoute: Bool? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.minimumDuration = minimumDuration
        self.maximumDuration = maximumDuration
        self.requiresGPSRoute = requiresGPSRoute
    }

    public var isActive: Bool {
        startDate != nil || endDate != nil || minimumDuration != nil || maximumDuration != nil || requiresGPSRoute != nil
    }

    public func matches(_ summary: WalkRouteSummary) -> Bool {
        if let startDate, summary.startDate < startDate { return false }
        if let endDate, summary.startDate >= endDate { return false }
        if let minimumDuration, summary.durationSeconds < minimumDuration { return false }
        if let maximumDuration, summary.durationSeconds > maximumDuration { return false }
        if let requiresGPSRoute, summary.hasGPSRoute != requiresGPSRoute { return false }
        return true
    }
}

public struct WalkRoutePageCursor: Equatable, Sendable {
    public let startDate: Date
    public let id: UUID
    public init(startDate: Date, id: UUID) { self.startDate = startDate; self.id = id }
}

public struct WalkMonth: Identifiable, Hashable, Sendable, Codable {
    public let startDate: Date
    public let endDate: Date
    public let walkCount: Int
    public init(startDate: Date, endDate: Date, walkCount: Int) {
        self.startDate = startDate; self.endDate = endDate; self.walkCount = walkCount
    }
    public var id: Date { startDate }
    public var year: Int { Calendar.current.component(.year, from: startDate) }
    public var monthName: String { startDate.formatted(.dateTime.month(.wide)) }
    public var title: String { startDate.formatted(.dateTime.month(.wide).year()) }

    public static func group(startDates: [Date], calendar: Calendar = .current) -> [WalkMonth] {
        let datesByMonth = Dictionary(grouping: startDates) { date in
            calendar.dateInterval(of: .month, for: date)?.start
        }
        return datesByMonth.compactMap { start, dates in
            guard
                let start,
                let interval = calendar.dateInterval(of: .month, for: start)
            else { return nil }
            return WalkMonth(startDate: start, endDate: interval.end, walkCount: dates.count)
        }
        .sorted { $0.startDate > $1.startDate }
    }
}

public struct WalkRouteSummaryPage: Sendable {
    public let summaries: [WalkRouteSummary]
    public let nextCursor: WalkRoutePageCursor?
    public let hasMore: Bool
    public init(summaries: [WalkRouteSummary], nextCursor: WalkRoutePageCursor?, hasMore: Bool) {
        self.summaries = summaries; self.nextCursor = nextCursor; self.hasMore = hasMore
    }
}

public struct WalkMetadata: Equatable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public init(id: UUID, startDate: Date, endDate: Date) {
        self.id = id; self.startDate = startDate; self.endDate = endDate
    }
}