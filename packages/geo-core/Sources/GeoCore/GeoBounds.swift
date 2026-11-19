import Foundation

public struct GeoBounds: Codable, Hashable, Sendable {
    public var minLatitude: Double
    public var maxLatitude: Double
    public var minLongitude: Double
    public var maxLongitude: Double

    public init?(points: [GeoCoordinate]) {
        guard let first = points.first(where: \.isValid) else { return nil }
        var minLatitude = first.latitude
        var maxLatitude = first.latitude
        var minLongitude = first.longitude
        var maxLongitude = first.longitude

        for point in points.dropFirst() where point.isValid {
            minLatitude = min(minLatitude, point.latitude)
            maxLatitude = max(maxLatitude, point.latitude)
            minLongitude = min(minLongitude, point.longitude)
            maxLongitude = max(maxLongitude, point.longitude)
        }

        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }

    public init(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }

    public var corners: [GeoCoordinate] {
        [
            GeoCoordinate(latitude: minLatitude, longitude: minLongitude),
            GeoCoordinate(latitude: minLatitude, longitude: maxLongitude),
            GeoCoordinate(latitude: maxLatitude, longitude: minLongitude),
            GeoCoordinate(latitude: maxLatitude, longitude: maxLongitude),
        ]
    }

    public func intersects(_ other: GeoBounds) -> Bool {
        maxLatitude >= other.minLatitude
            && other.maxLatitude >= minLatitude
            && maxLongitude >= other.minLongitude
            && other.maxLongitude >= minLongitude
    }

    public static func viewport(
        center: GeoCoordinate,
        latitudeDelta: Double,
        longitudeDelta: Double,
        margin: Double = 0.15
    ) -> GeoBounds {
        let latitudePad = max(latitudeDelta, 1e-6) * (0.5 + margin)
        let longitudePad = max(longitudeDelta, 1e-6) * (0.5 + margin)
        return GeoBounds(
            minLatitude: max(-90, center.latitude - latitudePad),
            maxLatitude: min(90, center.latitude + latitudePad),
            minLongitude: max(-180, center.longitude - longitudePad),
            maxLongitude: min(180, center.longitude + longitudePad)
        )
    }

    public func expanded(byKilometers kilometers: Double) -> GeoBounds {
        let latitudePad = kilometers / 111.32
        let midLatitude = (minLatitude + maxLatitude) / 2
        let longitudePad = latitudePad / max(0.15, cos(midLatitude * .pi / 180))
        return GeoBounds(
            minLatitude: max(-90, minLatitude - latitudePad),
            maxLatitude: min(90, maxLatitude + latitudePad),
            minLongitude: max(-180, minLongitude - longitudePad),
            maxLongitude: min(180, maxLongitude + longitudePad)
        )
    }
}
