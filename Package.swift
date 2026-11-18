// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HominemSwift",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "WalksCore", targets: ["WalksCore"]),
    ],
    targets: [
        .target(
            name: "WalksCore",
            path: "packages/walks-core/Sources/WalksCore"
        ),
        .testTarget(
            name: "WalksCoreTests",
            dependencies: ["WalksCore"],
            path: "packages/walks-core/Tests/WalksCoreTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
