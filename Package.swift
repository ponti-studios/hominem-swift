// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "HominemSwift",
  platforms: [.macOS(.v15), .iOS(.v18), .watchOS(.v10)],
  products: [
    .library(name: "WalksCore", targets: ["WalksCore"]),
    .library(name: "PlaceCore", targets: ["PlaceCore"]),
    .library(name: "GeoCore", targets: ["GeoCore"]),
    .library(name: "UtilityCore", targets: ["UtilityCore"]),
    .library(name: "FlightCore", targets: ["FlightCore"]),
    .library(name: "ParcelCore", targets: ["ParcelCore"]),
    .library(name: "TransitCore", targets: ["TransitCore"]),
    .library(name: "HominemAuth", targets: ["HominemAuth"]),
    .library(name: "HominemAuthUI", targets: ["HominemAuthUI"]),
    .library(name: "WaveformCore", targets: ["WaveformCore"]),
    .library(name: "WaveformUI", targets: ["WaveformUI"]),
    .library(name: "WaveformCapture", targets: ["WaveformCapture"]),
    .executable(name: "WaveformApp", targets: ["WaveformApp"]),
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
    .target(
      name: "HominemAuth",
      path: "packages/hominem-auth/Sources/HominemAuth"
    ),
    .target(
      name: "HominemAuthUI",
      dependencies: ["HominemAuth"],
      path: "packages/hominem-auth/Sources/HominemAuthUI"
    ),
    .target(
      name: "WaveformCore",
      path: "packages/waveform/Sources/WaveformCore"
    ),
    .target(
      name: "WaveformUI",
      dependencies: ["WaveformCore"],
      path: "packages/waveform/Sources/WaveformUI"
    ),
    .target(
      name: "WaveformCapture",
      dependencies: ["WaveformCore"],
      path: "packages/waveform/Sources/WaveformCapture"
    ),
    .executableTarget(
      name: "WaveformApp",
      dependencies: ["WaveformCore", "WaveformUI"],
      path: "packages/waveform/Sources/WaveformApp",
      exclude: ["Info.plist"],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist",
          "-Xlinker", "packages/waveform/Sources/WaveformApp/Info.plist",
        ])
      ]
    ),
    .testTarget(
      name: "WaveformCoreTests",
      dependencies: ["WaveformCore"],
      path: "packages/waveform/Tests/WaveformCoreTests"
    ),
    .testTarget(
      name: "WaveformUITests",
      dependencies: ["WaveformUI", "WaveformCore"],
      path: "packages/waveform/Tests/WaveformUITests"
    ),
    .testTarget(
      name: "WaveformCaptureTests",
      dependencies: ["WaveformCapture", "WaveformCore"],
      path: "packages/waveform/Tests/WaveformCaptureTests"
    ),
    .testTarget(
      name: "HominemAuthTests",
      dependencies: ["HominemAuth"],
      path: "packages/hominem-auth/Tests/HominemAuthTests"
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
