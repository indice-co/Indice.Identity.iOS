Implementation review — 14 September 2026

Scope: the current Swift package working tree, including the two pre-existing edits in IdentityClient.swift and CryptoKeys.swift. This review concerns implementation correctness, independently of the proposed user-device architecture. No production source was changed. P1 means a high-priority correctness or security fix; P2 means a normal-priority bug fix. Findings marked “source” were established by tracing the implementation, without exercising the affected Keychain or server flow.

1. **[P1] Biometric token failures are returned as successful login.** Evidence: source.

   [AuthorizationService.swift:155](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/AuthorizationService.swift:155). After grant generation succeeds, a token-endpoint error is caught, signingData is cleared, and the function returns normally. This includes rejected credentials and network errors. A consumer awaiting loginBiometric() cannot distinguish this from success, and previously stored tokens can remain present. Rethrow the original error after cleanup, and publish the signing context only after successful authentication.

2. **[P1] An in-flight login or refresh can restore tokens after logout.** Evidence: reproduced with a suspended mock authorization request.

   [AuthorizationService.swift:191](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/AuthorizationService.swift:191). While authorize() is suspended, revokeTokens() can run and clear the session. When authorization resumes, its response is stored unconditionally. The reproduction observed empty storage after logout followed by populated storage when the earlier login completed. Account changes and overlapping logins have the same stale-result problem. Invalidate outstanding operations with a session generation and check it before committing tokens; coordinate concurrent refreshes. Actor isolation does not make an asynchronous operation transactional: [Swift actor reentrancy](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md#actor-reentrancy).

3. **[P1] Starting reenrollment destroys the currently working credential.** Evidence: source.

   [DevicesService.swift:229](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/DevicesService.swift:229), also the biometric path at line 293. Both paths delete the existing key and create its replacement before initialization, OTP verification, or completion succeeds. A failed initialization, abandoned flow, or incorrect OTP can leave the server registered against the old credential while the device has lost that credential. Create a separately tagged pending key, retain the active credential until replacement succeeds, and handle promotion/recovery explicitly.

4. **[P1] Cancellation can still perform enrollment or device trust.** Evidence: trust path reproduced; enrollment path established from source.

   [DevicesService.swift:383](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/DevicesService.swift:383). A cancelled device selection becomes a nil swapDeviceId, after which trust() is still called. The reproduction recorded a PUT to /api/my/devices/this/trust after .aborted. The PIN and biometric continuations similarly convert .aborted into a nil OTP and still call complete(); a server flow that does not require another OTP may complete enrollment. Return or throw a cancellation result before any completing mutation, and dispose only of pending enrollment material.

5. **[P1] A configured client secret is included in the browser authorization URL.** Evidence: source; applies when client.secret is non-nil.

   [AuthorizationService.swift:262](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/AuthorizationService.swift:262). authorizationUrl() puts client_secret in its query parameters. Opening or logging this URL exposes the configured credential through the URL itself. Remove it from the authorization URL; use the configured client-authentication mechanism at the token endpoint where applicable.

6. **[P2] The signing context can change between the signature and public-key extraction.** Evidence: source.

   [AuthorizationService.swift:176](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/AuthorizationService.swift:176). The method checks signingData, awaits signing on another actor, then force-unwraps the mutable property again. A concurrent revoke can set it to nil and cause a crash; concurrent enrollment can replace it and produce a signature/public-key mismatch. Capture one context in a local constant and validate the session generation before returning. Separately, successful password login does not clear a previous account's signing context, so its ownership needs validation when replacing the authenticated identity.

7. **[P2] Enrollment can commit remotely while losing or failing to persist its local result.** Evidence: source.

   [DevicesService.swift:254](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/DevicesService.swift:254), also the biometric completion at line 319. After complete() succeeds, the service awaits a device-information fetch before saving registrationId. If that fetch fails, the catch clears the enrollment marker and the returned ID is not saved. The Bool from registration-ID storage is also ignored, and AuthRegistrationContext.store() returns true even when its storage.store() returns false. Treat remote completion, durable credential persistence, and metadata refresh as distinct outcomes. Preserve the completion result for recovery, propagate storage failures, and prevent a metadata-refresh error from discarding successful enrollment.

8. **[P2] Access-token revocation failure prevents refresh-token revocation.** Evidence: reproduced.

   [AuthorizationService.swift:227](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/AuthorizationService.swift:227). Tokens are cleared locally before two sequential throwing revocation calls. If revoking the access token fails, revocation of the refresh token is never attempted and the local copy needed to retry has already been discarded. The reproduction recorded only access_token. Attempt both revocations independently and surface their outcomes; preserve a deliberate retry mechanism where required.

9. **[P2] Quick-login status can remain true after credential invalidation.** Evidence: source.

   [DevicesService.swift:104](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/DevicesService.swift:104). hasRegistered(for:) decodes a stored deviceId but only compares the mode. An ID reset therefore does not invalidate the answer. removeRegistrationDevicePin() and removeRegistrationFingerprint() delete keys without clearing their registration markers or updating the cached support flags. Consumers can continue offering an unusable login method. Check the binding identity and clear/update the relevant metadata together with credential removal.

10. **[P2] Authorization-details extraction corrupts valid JSON or selects the wrong member.** Evidence: reproduced with valid input documents.

    [RawJSONExtractorError.swift:25](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Utilities/RawJSONExtractorError.swift:25). The bracket scanner counts delimiters inside quoted strings and the regex takes the first matching key at any nesting level. A details array containing a label of "]" produced truncated JSON; a label of "[" produced an extra closing brace; a nested authorization_details preceding the root property was selected instead of the root property. Use a JSON parser with an explicit root-member lookup. If preserving the exact source bytes is necessary, use a tokenizer that handles strings, escapes, nesting, and complete input validation.

11. **[P2] UI-observable state is published without main-actor isolation.** Evidence: source; no SwiftUI runtime test performed.

    [UserInformation.swift:30](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/UserInformation.swift:30) and [DevicesService.swift:50](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/DevicesService.swift:50). UserData, DevicesData, and QuickLoginStatus are public ObservableObjects marked @unchecked Sendable, while service actors mutate their published properties on their own executors. There is no main-actor hop for the UI binding API. Isolate these presentation objects to MainActor and transfer snapshots from the services, or expose an explicitly isolated observation mechanism.

12. **[P2] Enrollment ignores the requested OTP delivery channel.** Evidence: source.

    [DevicesService.swift:244](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/DevicesService.swift:244), also line 308. Both public enrollment methods accept otpChannel, but neither passes it to request construction. pinInit() and biometrictInit() do not accept it, so the request's channel stays nil. A caller explicitly selecting Viber, for example, gets the server's default channel. Thread the parameter through both helpers and verify the serialized request.

13. **[P2] Grant decoration loses the distinction between client and user grants.** Evidence: reproduced.

    [Grant.swift:98](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Protocols/Grant.swift:98). OAuthParamsWrapper forwards grantType and params, but not isUserGrant. It therefore inherits true, including when wrapping ClientCredentialsGrant. Passing a grant returned by appendDefaultParameters() to an API that decorates it again changes its scope from appScope to userScope. The reproduction observed app-scope on the first pass and user-scope on the second. Forward parent.isUserGrant and make default decoration safe to repeat.

14. **[P2] A default device-registration update can disable existing push registration.** Evidence: Swift source plus the platform handler inspected during the preceding review; deployed platform versions should be checked.

    [DeviceExtensions.swift:12](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Models/Extensions/DeviceExtensions.swift:12). updateThisDeviceRegistration() defaults pnsHandle to nil, then serializes isPushNotificationsEnabled as false with no handle. The inspected [platform UpdateDevice handler](https://github.com/indice-co/Indice.Platform/blob/a30c96cac048071b29ef716bde0c44e2b414befc/src/Indice.Features.Identity.Server/Devices/DeviceHandlers.cs#L116) unregisters an enabled device when no new handle is supplied. Distinguish preserving the existing push configuration from explicitly clearing it; metadata updates should not require callers to resend push state.

Additional implementation observations:

- [ServiceHub.swift:139](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/ServiceHub.swift:139) owns DevicesService, which strongly owns the same ServiceHub. Once devicesService is initialized, this forms a retain cycle. Replace the back-reference with the narrow dependency it needs, or an appropriate weak reference.
- [ThisDeviceRepository.swift:59](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Repositories/ThisDeviceRepository.swift:59) performs an unsynchronized read-create-store sequence. Concurrent first access from the authorization and device actors can return different generated IDs even if the underlying ValueStorage makes individual reads and writes safe. Make ID initialization atomic.
- [Callbacks.swift:39](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Utilities/Callbacks.swift:39) does not specify Sendable or actor isolation for DeviceSelection. With Swift 6.4 in Swift 6 mode, passing a plain closure from the harness's main-actor context to enableDeviceTrust() failed compilation. An explicit @Sendable closure worked. Define the callback's intended isolation in the public API, including how UI selection is presented.
- [DevicesService.swift:191](/Users/nikolaskonstantakopoulos/Projects/Mobile/Platform/Identity.iOS/Sources/IdentityClient/Client/Services/DevicesService.swift:191) force-unwraps the current device after a list fetch. Use the direct device lookup or creation response and handle absence explicitly. A list response that does not contain the device should not crash the process or, earlier in this method, automatically prove that the binding needs a new ID.
- Several public request structs, including CreateDeviceRequest, UpdateDeviceRequest, ValidatePasswordRequest, and ValidateUsernameRequest, have no public initializer. Their public repository APIs are difficult to call from another module without decoding an instance. Review which DTOs are intentionally public construction APIs.

Validation and limits:

- swift test completed successfully on the installed macOS toolchain. It ran one empty XCTest method, so this does not validate the implementation's behavior.
- Tests/IdentityClientTests/.swift contains a storage test but was not discovered by that run.
- An isolated harness compiled the current package sources and the checked-out NetworkUtilities sources with Swift 6.4 in Swift 6 mode. It reproduced findings 2, 4 (trust cancellation), 8, 10, and 13 using synthetic values and mock networking. No requests went to an identity server.
- The harness also checked two suspected issues that did not reproduce: nil client_secret was omitted from grant parameters, and a lowercase explicitly supplied Authorization header was preserved. Neither is reported as a bug.
- Biometric prompts, physical-device Keychain behavior, APNs, and deployed-server integration were not exercised. The signing crash is an identified interleaving, not a reproduced crash. Keychain overwrite semantics were not established and are not reported as a confirmed defect.
- Temporary reproduction source and output are available at [ReviewHarness.swift](/private/tmp/identity-implementation-review/ReviewHarness.swift) and [results.txt](/private/tmp/identity-implementation-review/results.txt).

Recommended order: fix authentication error propagation and stale-result rejection first; then make enrollment cancellation, credential replacement, and persistence consistent; then address signing-context lifetime, parsing, observation, and request construction. Add focused regression tests for these behaviors before moving them into a new user-device coordinator.
