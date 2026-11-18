import Foundation
import MapKit

public struct MapKitPlaceSearch: PlaceSearching {
    public init() {}

    public func search(_ query: String, near: PlaceCoordinate?, limit: Int = 20) async throws -> [PlaceSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw PlaceSearchError.emptyQuery
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = [.address, .pointOfInterest]
        if let near {
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: near.latitude,
                    longitude: near.longitude
                ),
                latitudinalMeters: 40_000,
                longitudinalMeters: 40_000
            )
        }

        let response = try await MKLocalSearch(request: request).start()
        let results = response.mapItems.prefix(limit).map(Self.result)
        guard !results.isEmpty else {
            throw PlaceSearchError.noResults
        }
        return results
    }

    private static func result(from item: MKMapItem) -> PlaceSearchResult {
        let placemark = item.placemark
        let name = item.name ?? placemark.name ?? "Unknown place"
        let address = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
        ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        let category = item.pointOfInterestCategory?.rawValue ?? ""

        return PlaceSearchResult(
            name: name,
            address: address,
            category: category,
            coordinate: PlaceCoordinate(
                latitude: placemark.coordinate.latitude,
                longitude: placemark.coordinate.longitude
            ),
            phone: item.phoneNumber,
            url: item.url?.absoluteString
        )
    }
}
