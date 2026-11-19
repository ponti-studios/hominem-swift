import Foundation
import GeoCore

public struct Flight: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var number: String
    public var origin: String
    public var destination: String
    public var departure: Date
    public var arrival: Date
    public var originCoordinate: GeoCoordinate?
    public var destinationCoordinate: GeoCoordinate?

    public init(
        id: UUID = UUID(),
        number: String,
        origin: String,
        destination: String,
        departure: Date,
        arrival: Date,
        originCoordinate: GeoCoordinate? = nil,
        destinationCoordinate: GeoCoordinate? = nil
    ) {
        self.id = id
        self.number = number
        self.origin = origin
        self.destination = destination
        self.departure = departure
        self.arrival = arrival
        self.originCoordinate = originCoordinate ?? AirportCatalog.coordinate(for: origin)
        self.destinationCoordinate = destinationCoordinate ?? AirportCatalog.coordinate(for: destination)
    }

    public var durationSeconds: TimeInterval {
        max(0, arrival.timeIntervalSince(departure))
    }
}
