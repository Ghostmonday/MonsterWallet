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
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
        // Downgrading to a version that doesn't use the C-module secp256k1 directly or handles it better.
        // Or sticking with 1.1.0 but acknowledging the manual fix required for C headers until we can properly migrate.
        .package(url: "https://github.com/argentlabs/web3.swift.git", exact: "1.1.0"),
        .package(url: "https://github.com/Boilertalk/secp256k1.swift.git", exact: "0.1.0")
    ],
    targets: [
        .target(
            name: "KryptoClaw",
            dependencies: [
                "BigInt",
                "CryptoSwift",
                .product(name: "web3.swift", package: "web3.swift"),
                .product(name: "secp256k1", package: "secp256k1.swift")
            ]),
        .testTarget(
            name: "KryptoClawTests",
            dependencies: ["KryptoClaw"]),
    ]
)
