import CoreLocation
import Foundation
import GeoCore

public struct TFLStation: Identifiable, Codable, Hashable, Sendable {
  public let id: String
  public var name: String
  public var coordinate: GeoCoordinate
  public var lines: [String]

  public init(
    id: String,
    name: String,
    coordinate: GeoCoordinate,
    lines: [String] = []
  ) {
    self.id = id
    self.name = name
    self.coordinate = coordinate
    self.lines = lines
  }

  public init(
    id: String,
    name: String,
    coordinate: CLLocationCoordinate2D,
    lines: [String] = []
  ) {
    self.init(
      id: id,
      name: name,
      coordinate: GeoCoordinate(coordinate),
      lines: lines
    )
  }
}

public struct JamCam: Identifiable, Codable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let coordinate: GeoCoordinate
  public let view: String
  public let imageURL: URL?
  public let videoURL: URL?
  public let isAvailable: Bool

  public init(
    id: String,
    name: String,
    coordinate: GeoCoordinate,
    view: String = "",
    imageURL: URL? = nil,
    videoURL: URL? = nil,
    isAvailable: Bool = true
  ) {
    self.id = id
    self.name = name
    self.coordinate = coordinate
    self.view = view
    self.imageURL = imageURL
    self.videoURL = videoURL
    self.isAvailable = isAvailable
  }
}

public protocol JamCamProviding: Sendable {
  func fetchCameras() async throws -> [JamCam]
}

public enum JamCamError: Error, Equatable, LocalizedError {
  case badStatus(Int)
  case badPayload

  public var errorDescription: String? {
    switch self {
    case .badStatus(let code):
      "TfL returned HTTP \(code)"
    case .badPayload:
      "TfL returned an unreadable camera feed"
    }
  }
}
