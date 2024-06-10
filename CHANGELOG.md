# Changelog

## [1.1.0] - 2024-06-10

### Updates
- Support for [Rich Authorization Requests (RAR), RFC-9396](https://datatracker.ietf.org/doc/html/rfc9396)


### Breaking Changes
- `OAuth2Grant` ctors change. Creating a grant doesn't require providing the client, or any identifiers. It is now handled internally. <br />
If you use the `AuthorizationService` methods that hide the underlying grant e.g. `login(username:password:)`, this change will not affect you.


## [version < 1.1.0]
The first Changelog file created at v 1.1.0, so no info before.. sorry!
