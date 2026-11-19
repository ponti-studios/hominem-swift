import Foundation
import CoreLocation

public struct PlaceSearchResult: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let name: String
    public let address: String
    public let category: String
    public let coordinate: PlaceCoordinate
    public let phone: String?
    public let url: String?

    public init(
        id: String,
        name: String,
        address: String,
        category: String,
        coordinate: PlaceCoordinate,
        phone: String? = nil,
        url: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.category = category
        self.coordinate = coordinate
        self.phone = phone
        self.url = url
    }

    public init(
        name: String,
        address: String,
        category: String,
        coordinate: PlaceCoordinate,
        phone: String? = nil,
        url: String? = nil
    ) {
        let latitude = (coordinate.latitude * 100_000).rounded() / 100_000
        let longitude = (coordinate.longitude * 100_000).rounded() / 100_000
        self.init(
            id: "place|\(Self.stableName(name))|\(latitude)|\(longitude)",
            name: name,
            address: address,
            category: category,
            coordinate: PlaceCoordinate(latitude: latitude, longitude: longitude),
            phone: phone,
            url: url
        )
    }

    public init(
        name: String,
        address: String,
        category: String,
        coordinate: CLLocationCoordinate2D,
        phone: String? = nil,
        url: String? = nil
    ) {
        self.init(
            name: name,
            address: address,
            category: category,
            coordinate: PlaceCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            phone: phone,
            url: url
        )
    }

    public var latitude: Double { coordinate.latitude }
    public var longitude: Double { coordinate.longitude }

    /// Identity form of a place name: canonical composition, trimmed, case-folded.
    static func stableName(_ name: String) -> String {
        name.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
