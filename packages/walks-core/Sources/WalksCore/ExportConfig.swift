import Foundation

public struct WalkArchiveConfiguration: Sendable, Equatable {
  public let containerIdentifier: String
  public let userVisibleFolderName: String
  public let manifestFilename: String

  public init(
    containerIdentifier: String,
    userVisibleFolderName: String = "Walks",
    manifestFilename: String = "manifest.json"
  ) {
    self.containerIdentifier = containerIdentifier
    self.userVisibleFolderName = userVisibleFolderName
    self.manifestFilename = manifestFilename
  }

  public func routeFilename(for id: UUID) -> String {
    "walk-\(id.uuidString.lowercased()).gpx"
  }
}

public enum ICloudExportConfiguration {
  public static let containerIdentifier = "iCloud.io.ponti.walksgpx"
  public static let userVisibleFolderName = "Walks GPX"
  public static let manifestFilename = "manifest.json"

  public static func routeFilename(for id: UUID) -> String {
    "walk-\(id.uuidString.lowercased()).gpx"
  }
}
