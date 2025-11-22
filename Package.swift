// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MonsterWallet",
    platforms: [
        .iOS(.v17),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MonsterWallet",
            targets: ["MonsterWallet"]),
    ],
    targets: [
        .target(
            name: "MonsterWallet"),
        .testTarget(
            name: "MonsterWalletTests",
            dependencies: ["MonsterWallet"]),
    ]
)
