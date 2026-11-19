import Foundation

public struct GeoCoordinateRegion: Codable, Hashable, Sendable {
    public var center: GeoCoordinate
    public var latitudeDelta: Double
    public var longitudeDelta: Double

    public init(center: GeoCoordinate, latitudeDelta: Double, longitudeDelta: Double) {
        self.center = center
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }

    public static let london = GeoCoordinateRegion(
        center: GeoCoordinate(latitude: 51.5074, longitude: -0.1278),
        latitudeDelta: 0.14,
        longitudeDelta: 0.20
    )

    public static func fitting(
        _ points: [GeoCoordinate],
        padding: Double = 1.4,
        minimumDelta: Double = 0.004
    ) -> GeoCoordinateRegion? {
        let valid = points.filter(\.isValid)
        guard let first = valid.first else { return nil }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for point in valid.dropFirst() {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }

        let latitudeDelta = max((maxLat - minLat) * padding, minimumDelta)
        var longitudeDelta = max((maxLon - minLon) * padding, minimumDelta)
        if longitudeDelta < latitudeDelta * 1.35 {
            longitudeDelta = latitudeDelta * 1.35
        }

        return GeoCoordinateRegion(
            center: GeoCoordinate(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            latitudeDelta: min(latitudeDelta, 160),
            longitudeDelta: min(longitudeDelta, 340)
        )
    }

    public func contains(_ coordinate: GeoCoordinate, padding: Double = 0) -> Bool {
        let latitudePadding = latitudeDelta * padding
        let longitudePadding = longitudeDelta * padding
        return coordinate.latitude >= center.latitude - latitudeDelta / 2 - latitudePadding
            && coordinate.latitude <= center.latitude + latitudeDelta / 2 + latitudePadding
            && coordinate.longitude >= center.longitude - longitudeDelta / 2 - longitudePadding
            && coordinate.longitude <= center.longitude + longitudeDelta / 2 + longitudePadding
    }
}

public typealias GeoRegion = GeoCoordinateRegion
