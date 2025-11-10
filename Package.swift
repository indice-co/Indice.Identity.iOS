// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Indice.Identity",
    platforms: [.iOS(.v14), .macOS(.v10_15)],
    products: [
        .library(
            name: "IdentityClient",
            targets: ["IdentityClient"]),
    ],
    dependencies: [
        // .package(url: "https://github.com/indice-co/Indice.Swift.Networking", .upToNextMinor(from: "1.4.0"))
        // .package(url: "https://github.com/indice-co/Indice.Swift.Networking", branch: "develop"),
        .package(path: "~/Projects/Mobile/Platform/Networking.iOS")
    ],
    targets: [
        .target(
            name: "IdentityClient",
            dependencies: [
                // .product(name: "NetworkUtilities", package: "Indice.Swift.Networking"),
                .product(name: "NetworkUtilities", package: "Networking.iOS"),
            ]
        ),
        .testTarget(
            name: "IdentityClientTests",
            dependencies: ["IdentityClient"]),
    ],
    swiftLanguageModes: [.v6]
)
