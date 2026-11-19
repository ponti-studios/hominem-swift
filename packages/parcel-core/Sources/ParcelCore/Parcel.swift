import Foundation
import GeoCore
import CoreLocation

public struct Parcel: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var trackingNumber: String
    public var carrier: String
    public var status: String
    public var lastLocation: GeoCoordinate?
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        trackingNumber: String,
        carrier: String,
        status: String,
        lastLocation: GeoCoordinate? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.trackingNumber = trackingNumber
        self.carrier = carrier
        self.status = status
        self.lastLocation = lastLocation
        self.updatedAt = updatedAt
    }

    public init(
        id: UUID = UUID(),
        trackingNumber: String,
        carrier: String,
        status: String,
        lastLocation: CLLocationCoordinate2D?,
        updatedAt: Date = .now
    ) {
        self.init(
            id: id,
            trackingNumber: trackingNumber,
            carrier: carrier,
            status: status,
            lastLocation: lastLocation.map(GeoCoordinate.init),
            updatedAt: updatedAt
        )
    }
}

public protocol ParcelProviding: Sendable {
    func fetchParcels() async throws -> [Parcel]
}
