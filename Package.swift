// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "HominemSwift",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [
    .library(name: "WalksCore", targets: ["WalksCore"]),
    .library(name: "PlaceCore", targets: ["PlaceCore"]),
    .library(name: "GeoCore", targets: ["GeoCore"]),
    .library(name: "UtilityCore", targets: ["UtilityCore"]),
    .library(name: "FlightCore", targets: ["FlightCore"]),
    .library(name: "ParcelCore", targets: ["ParcelCore"]),
    .library(name: "TransitCore", targets: ["TransitCore"]),
  ],
  targets: [
    .target(
      name: "WalksCore",
      dependencies: ["GeoCore"],
      path: "packages/walks-core/Sources/WalksCore"
    ),
    .target(
      name: "PlaceCore",
      path: "packages/place-core/Sources/PlaceCore"
    ),
    .target(
      name: "GeoCore",
      path: "packages/geo-core/Sources/GeoCore"
    ),
    .target(
      name: "UtilityCore",
      path: "packages/utility-core/Sources/UtilityCore"
    ),
    .target(
      name: "FlightCore",
      dependencies: ["GeoCore"],
      path: "packages/flight-core/Sources/FlightCore"
    ),
    .target(
      name: "ParcelCore",
      dependencies: ["GeoCore"],
      path: "packages/parcel-core/Sources/ParcelCore"
    ),
    .target(
      name: "TransitCore",
      dependencies: ["GeoCore"],
      path: "packages/transit-core/Sources/TransitCore"
    ),
    .testTarget(
      name: "WalksCoreTests",
      dependencies: ["WalksCore", "GeoCore"],
      path: "packages/walks-core/Tests/WalksCoreTests"
    ),
    .testTarget(
      name: "PlaceCoreTests",
      dependencies: ["PlaceCore"],
      path: "packages/place-core/Tests/PlaceCoreTests"
    ),
    .testTarget(
      name: "GeoCoreTests",
      dependencies: ["GeoCore"],
      path: "packages/geo-core/Tests/GeoCoreTests"
    ),
    .testTarget(
      name: "UtilityCoreTests",
      dependencies: ["UtilityCore"],
      path: "packages/utility-core/Tests/UtilityCoreTests"
    ),
    .testTarget(
      name: "FlightCoreTests",
      dependencies: ["FlightCore"],
      path: "packages/flight-core/Tests/FlightCoreTests"
    ),
    .testTarget(
      name: "ParcelCoreTests",
      dependencies: ["ParcelCore"],
      path: "packages/parcel-core/Tests/ParcelCoreTests"
    ),
    .testTarget(
      name: "TransitCoreTests",
      dependencies: ["TransitCore"],
      path: "packages/transit-core/Tests/TransitCoreTests"
    ),
  ],
  swiftLanguageModes: [.v5]
)
