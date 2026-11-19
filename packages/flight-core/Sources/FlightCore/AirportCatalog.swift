import GeoCore

public enum AirportCatalog {
    public static let all: [String: GeoCoordinate] = [
        "LHR": GeoCoordinate(latitude: 51.4700, longitude: -0.4543),
        "LGW": GeoCoordinate(latitude: 51.1537, longitude: -0.1821),
        "JFK": GeoCoordinate(latitude: 40.6413, longitude: -73.7781),
        "EWR": GeoCoordinate(latitude: 40.6895, longitude: -74.1745),
        "LAX": GeoCoordinate(latitude: 33.9416, longitude: -118.4085),
        "SFO": GeoCoordinate(latitude: 37.6213, longitude: -122.3790),
        "ORD": GeoCoordinate(latitude: 41.9742, longitude: -87.9073),
        "CDG": GeoCoordinate(latitude: 49.0097, longitude: 2.5479),
        "AMS": GeoCoordinate(latitude: 52.3105, longitude: 4.7683),
        "FRA": GeoCoordinate(latitude: 50.0379, longitude: 8.5622),
        "BCN": GeoCoordinate(latitude: 41.2974, longitude: 2.0833),
        "FCO": GeoCoordinate(latitude: 41.8003, longitude: 12.2389),
        "DXB": GeoCoordinate(latitude: 25.2532, longitude: 55.3657),
        "HND": GeoCoordinate(latitude: 35.5494, longitude: 139.7798),
        "SIN": GeoCoordinate(latitude: 1.3644, longitude: 103.9915),
        "SYD": GeoCoordinate(latitude: -33.9399, longitude: 151.1753),
        "GRU": GeoCoordinate(latitude: -23.4356, longitude: -46.4731),
        "CPT": GeoCoordinate(latitude: -33.9715, longitude: 18.6021),
    ]

    public static func coordinate(for code: String) -> GeoCoordinate? {
        all[code.uppercased()]
    }
}
