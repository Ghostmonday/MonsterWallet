// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KryptoClaw",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KryptoClaw",
            targets: ["KryptoClaw"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KryptoClaw",
            dependencies: []),
        .testTarget(
            name: "KryptoClawTests",
            dependencies: ["KryptoClaw"]),
    ]
)
