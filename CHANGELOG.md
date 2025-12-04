# Changelog

## [1.3.0] - 2025-12-04

### Breaking changes
- Rename package to `IdentityClient`. Find/Replace all your imports fromt `import Indice_Identity` to `import IdentityClient`, it'll be fine.
- Rename property `IdentityClient.authorizationService` to `IdentityClient.authService` for brevity. 
- Remove `IdentityClientFactory`. User `IdentityClient.init` as it is a concrete type now. 
- `IdentityClient.init` property `NetworkOptions` do not provide the instance of the client.
- `AuthorizationService.generateGrant(for:)` returns `AuthorizationSecurityData`, a wrapper over the `DeviceAuthenticationGrant`. The grant is available via the `grant` property of the struct.

### Changes
- Using swift tools 6.2. Various models and apis are now marked as `Sendable`.
- `IdentityClient` exposes all its services as a type alias, to avoid name conflicts on common type names. 
- Added a `SecureStorage` class, that uses the SecItem API, used for sensitive data storage.
- `AuthorizationService` exposes a `signWithBiometricSecurityContext(_:dataType:)` method that signs a `Swift.Data` struct with the security context of the latest successful biometric grant flow, if available.
- Added default implementation of `CurrentDeviceInfoProvider` protocol, if `UIKit` and `DeviceKit` are available. Available as a static property `uiDevice`. 
- Added `CriticalSectionLock` a wrapper over an __non reentrant__ `os_unfair_lock`. Used internaly, available also for you!

### Fixes
- Use of internal `AuthRegistrationContext` to better represent the device's biometric/fourpin registration state, removing the requirement for the consumer to remove/update the relevant states after the `deviceId` changes.


## [1.2.1] - 2024-09-11

### Changes
- `IdentityClient` doesn't use the `NetworkClient` any more as a default http client.<br>
  If you rely on the `NetworkClient` included with this package, *dont*. It will eventually be fully removed as a dependency. 
- `NetworkOptions` to include `ErrorParser` in order to transform the relevant errors of the `RequestProcessor` to concrete ones if possible.
- `Client.urls` is now nullable.   

### Breaking Changes
- Changed errors thrown by the client. @see `IdentityClient.Error`.
- `IdentityClientFactory.create` network builder lambda to return `NetworkOptions`.



## [1.1.1] - 2024-07-23

### Updates
- Added `Client.Urls` ctor for common used client urls.
- Added `Client.Scope` struct to replace the string based scopes declaration when instantiating a `Client`. 



## [1.1.0] - 2024-06-10

### Updates
- Support for [Rich Authorization Requests (RAR), RFC-9396](https://datatracker.ietf.org/doc/html/rfc9396)


### Breaking Changes
- `OAuth2Grant` ctors change. Creating a grant doesn't require providing the client, or any identifiers. It is now handled internally. <br />
If you only use the `AuthorizationService` methods that hide the underlying grant e.g. `login(username:password:)`, this change will not affect you.
