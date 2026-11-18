// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WalksCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "WalksCore", targets: ["WalksCore"]),
    ],
    targets: [
        .target(name: "WalksCore", path: "Sources/WalksCore"),
        .testTarget(name: "WalksCoreTests", dependencies: ["WalksCore"], path: "Tests/WalksCoreTests"),
    ],
    swiftLanguageModes: [.v5]
)