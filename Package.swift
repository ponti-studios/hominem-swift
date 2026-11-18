// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HominemSwift",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "WalksCore", targets: ["WalksCore"]),
        .library(name: "PlaceCore", targets: ["PlaceCore"]),
    ],
    targets: [
        .target(
            name: "WalksCore",
            path: "packages/walks-core/Sources/WalksCore"
        ),
        .target(
            name: "PlaceCore",
            path: "packages/place-core/Sources/PlaceCore"
        ),
        .testTarget(
            name: "WalksCoreTests",
            dependencies: ["WalksCore"],
            path: "packages/walks-core/Tests/WalksCoreTests"
        ),
        .testTarget(
            name: "PlaceCoreTests",
            dependencies: ["PlaceCore"],
            path: "packages/place-core/Tests/PlaceCoreTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
