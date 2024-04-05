// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Indice.Identity",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "IndiceIdentity",
            targets: ["Indice.Identity"]),
    ],
    dependencies: [
        .package(url: "https://github.com/indice-co/Indice.Swift.Networking", .upToNextMajor(from: "1.2.3"))
    ],
    targets: [
        .target(
            name: "Indice.Identity",
            dependencies: [
                .product(name: "IndiceNetworkClient", package: "Indice.Swift.Networking")
            ]
        ),
        .testTarget(
            name: "Indice.IdentityTests",
            dependencies: ["Indice.Identity"]),
    ]
)
