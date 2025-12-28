# Indice.Identity.iOS  ![alt text](icon/icon-64.png "Indice logo")
![Swift 6.2](https://img.shields.io/badge/swift-6.2-orange.svg)
![platform iOs 13](https://img.shields.io/badge/iOS-v13-blue.svg)
![platform macOs 10.15](https://img.shields.io/badge/macOS-v10.15-blueviolet.svg)

Swift Library Identity SDK.

## Installation

### Swift Package Manager

Add Indice.Identity.iOS as a dependency
# Identity.iOS

Identity.iOS is a Swift package that provides client-side components for interacting with an Identity service. It contains the `IdentityClient` module used by iOS apps and platform components to handle authentication, device management, user registration, and account operations.

## Requirements

- Swift 5.3 or newer
- macOS for local development (Xcode recommended)

## Installation

Add this package as a Swift Package Manager dependency in your Xcode project or `Package.swift`:

1. In Xcode: File → Add Packages… and point to this repository.
2. Or add to `Package.swift` dependencies:

```swift
.package(url: "https://github.com/indice-co/Indice.Identity.iOS", from: "1.3.1")
```

## Usage

Import the module where you need it:

```swift
import IdentityClient
```

See `Sources/IdentityClient` for available services, repositories, and models (for example `Services`, `Repositories`, `Models`, and `Protocols`). The package is organized around a small set of service APIs (account, authorization, devices, user registration) and pluggable protocols for configuration and token storage.


## Further Reading

- API and implementation live under `Sources/IdentityClient`.
- Unit tests are under `Tests/IdentityClientTests`.

## Initialization

A minimal Swift example showing how to create an `IdentityClient` instance. Replace the placeholders with your real implementations for `RequestProcessor` and `ErrorParser`.

```swift
import IdentityClient

// 1. Create a configuration for your Identity Server
let config = IdentityConfig(baseUrl: URL(string: "https://identity.example.com")!)

// 2. Create a Client descriptor
let client = Client(
	id: "your-client-id",
	secret: "your-secret",
	userScope: [.openId, .profile],
	appScope: [.identity],
	urls: .init(commonForRedirectScheme: "myapp"))

// 3. Provide networking options (supply your RequestProcessor and ErrorParser)
let networkOptions = NetworkOptions(
	processorBuilder: { /* return your RequestProcessor instance */ },
	errorParser: /* your ErrorParser instance */
)

// 4. Construct the IdentityClient (on platforms with UIKit you can omit `currentDeviceInfoProvider`)
let identityClient = IdentityClient(
	client: client,
	configuration: config,
	currentDeviceInfoProvider: /* CurrentDeviceInfoProvider implementation or .uiDevice */, 
	networkOptions: networkOptions
)

// Use services
// await identityClient.authService.login(...)
```



