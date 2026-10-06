// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Indice.Identity",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(
            name: "IdentityClient",
            targets: ["IdentityClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/indice-co/Indice.HTTP.Swift", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "IdentityClient",
            dependencies: [
                .product(name: "NetworkUtilities", package: "Indice.HTTP.Swift")
            ]
        ),
        .testTarget(
            name: "IdentityClientTests",
            dependencies: ["IdentityClient"]),
    ],
    swiftLanguageModes: [.v6]
)
