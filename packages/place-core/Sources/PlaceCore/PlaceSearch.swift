import Foundation

public protocol PlaceSearching: Sendable {
  func search(_ query: String, near: PlaceCoordinate?, limit: Int) async throws
    -> [PlaceSearchResult]
}

public enum PlaceSearchError: Error, LocalizedError {
  case emptyQuery
  case noResults

  public var errorDescription: String? {
    switch self {
    case .emptyQuery:
      "Type something to search for."
    case .noResults:
      "Apple Maps found no matches."
    }
  }
}
