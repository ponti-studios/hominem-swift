import Foundation

public struct WalkExportManifest: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public let schemaVersion: Int
    public let generatedAt: Date
    public let walks: [WalkExportManifestEntry]

    public init(routes: [WalkRoute], generatedAt: Date = .now) {
        let entries = Dictionary(routes.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
            .values.map { WalkExportManifestEntry(route: $0) }
        self.init(entries: entries, generatedAt: generatedAt)
    }

    public init(entries: [WalkExportManifestEntry], generatedAt: Date = .now) {
        schemaVersion = Self.currentSchemaVersion
        self.generatedAt = generatedAt
        let unique = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        walks = unique.values.sorted {
            if $0.startDate != $1.startDate { return $0.startDate < $1.startDate }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    public static func encode(_ manifest: WalkExportManifest) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(manifest)
    }

    public static func decode(_ data: Data) throws -> WalkExportManifest {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(WalkExportManifest.self, from: data)
        guard manifest.schemaVersion == currentSchemaVersion else {
            throw WalkExportManifestError.unsupportedSchema(manifest.schemaVersion)
        }
        return manifest
    }
}

public struct WalkExportManifestEntry: Codable, Equatable, Sendable {
    public let id: UUID
    public let filename: String
    public let startDate: Date
    public let endDate: Date
    public let pointCount: Int

    public init(route: WalkRoute, filename: String? = nil) {
        id = route.id
        self.filename = filename ?? ICloudExportConfiguration.routeFilename(for: route.id)
        startDate = route.startDate
        endDate = route.endDate
        pointCount = route.locations.count
    }
}

public enum WalkExportManifestError: LocalizedError, Equatable {
    case unsupportedSchema(Int)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            "The walk export manifest uses unsupported schema version \(version)."
        }
    }
}
