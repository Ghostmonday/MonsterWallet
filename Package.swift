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
        // Fix: Use correct package name/product
        .package(url: "https://github.com/argentlabs/web3.swift.git", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "KryptoClaw",
            dependencies: [
                "BigInt",
                "CryptoSwift",
                .product(name: "web3", package: "web3.swift") // Fixed product name
            ]),
        .testTarget(
            name: "KryptoClawTests",
            dependencies: ["KryptoClaw"]),
    ]
)
