# Changelog

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
