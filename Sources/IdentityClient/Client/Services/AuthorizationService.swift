//
//  AuthorizationService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation


public actor AuthorizationService: AuthorizationSecurityDataHolder {

    public typealias SecurityData = AuthorizationSecurityData
    public struct AuthorizationDetails {
        internal let value: Data
    }
    
    private let authRepository: AuthRepository
    private let accountRepository: MyAccountRepository
    private let devicesRepository: DevicesRepository
    private let thisDeviceRepository: ThisDeviceRepository
    private let tokenStorage: TokenStorage
    private let client: Client
    private let configuration: IdentityConfig
    
    internal var signingData: AuthorizationSecurityData?
    
    internal init(authRepository: AuthRepository,
                  accountRepository: MyAccountRepository,
                  devicesRepository: DevicesRepository,
                  thisDeviceRepository: ThisDeviceRepository,
                  tokenStorage: TokenStorage,
                  client: Client,
                  configuration: IdentityConfig) {
        self.authRepository = authRepository
        self.accountRepository = accountRepository
        self.devicesRepository = devicesRepository
        self.thisDeviceRepository = thisDeviceRepository
        self.tokenStorage = tokenStorage
        self.client = client
        self.configuration = configuration
    }
    
    
    /// Helper method that asynchronously create a DeviceAuthenticationGrant
    ///
    /// Creating a "Device Pin/ 4Pin" or "Biometric" grant involves a bit of crypto things as well as challenge exchange.
    /// This method covers all that and just hands you a OAuth2Grant ready to go.
    ///
    /// Methods already exist to login with biometric or for pin without exposing the underlying ``OAuth2Grant``, but in case you need one, well here you go.
    public func generateGrant(for info: DeviceAuthenticationGrant.Info) async throws -> DeviceGrantData {
        switch info {
        case .biometric:
            let keys = try keyOrThrow(locked: true, tagged: .fingerprint)
            
            let codeVerifier = CryptoRandom.uniqueId()
            let verifierHash = CryptoUtils.challenge(for: codeVerifier)
            let ids = thisDeviceRepository.ids
            
            let response = try await devicesRepository.authorize(
                authRequest: try .biometrictAuth(
                    codeChallenge: verifierHash,
                    deviceIds: ids,
                    client: client))
            
            let publicPem       = try CryptoUtils.pem(for: keys)
            let signedChallenge = try CryptoUtils.sign(string: response.challenge, with: keys)
            
            return .init(
                grant: .biometrict(
                    challenge: response.challenge,
                    codeSignature: signedChallenge,
                    codeVerifier: codeVerifier,
                    publicKey: publicPem),
                securityData: .init(
                    key: keys.private))
            
        case .devicePin(let value):
            let keys = try keyOrThrow(locked: false, tagged: .devicePin)

            let ids = thisDeviceRepository.ids
            let pinHash = try CryptoUtils.prepare(pin: value,
                                                  withDeviceId: ids.device,
                                                  and: keys)
            
            return .init(
                grant: .pin(value: pinHash),
                securityData: nil)
        }
    }
    
    
    /// Returns a token response without storing it internally
    ///
    /// To be used for "ad-hoc" token generation
    public func generateToken(for grant: any OAuth2Grant) async throws -> TokenResponse {
        let final = grant
            .with(client: client)
            .with(deviceIds: thisDeviceRepository.ids)
        
        return try await authRepository.authorize(grant: final)
    }

    
    /// Return an OAuth2Grant that includes some default extra parameters.
    public func appendDefaultParameters(to grant: any OAuth2Grant) -> any OAuth2Grant {
        grant
            .with(client: client)
            .with(deviceIds: thisDeviceRepository.ids)
    }
    
    
    /// Will try the slice the `errorJsonData` and exract the relevant "authorization\_details"
    /// as excpected by the [Rich Authorization Request RFC 9396](https://datatracker.ietf.org/doc/html/rfc9396).
    ///
    /// `errorJsonData` is expected as the full `Data` reponse body from a failed HTTP request.
    public func extractAuthorizationDetailsFrom(errorJsonData jsonData: Data) throws -> AuthorizationDetails {
        let data = try RawJSONExtractor.extractValue(
            forKey: "authorization_details",
            from: jsonData)
        
        return AuthorizationDetails(value: data)
    }
    
    
    /// Try to authorize the current client with a `ClientCredentialsGrant` grant.
    ///
    /// See also: generateGrant(for: DeviceAuthenticationGrant.Info) async throws -> OAuth2Grant
    public func authorizeClient() async throws {
        try await login(withGrant: .clientCredentials())
    }
    
    
    /// Try login using the password grant
    ///
    /// *login...* methods, do store the relevant token response.
    public func login(username: String, password: String) async throws {
        try await login(withGrant: .password(username: username, password: password))
    }
    
    
    /// Try login using the device\_authentication grant - using the 4pin mode. *login...* methods, do store the relevant token response.
    ///
    /// See also: generateGrant(for: DeviceAuthenticationGrant.Info) async throws -> OAuth2Grant
    public func login(withPin pin: String) async throws {
        let data = try await generateGrant(
            for: .devicePin(value: pin))
        
        try await login(withGrant: data.grant)
    }
    
    
    /// Try login using the device\_authentication grant - using the fingerprint mode. *login...* methods, do store the relevant token response.
    /// See also: ``generateGrant(for: DeviceAuthenticationGrant.Info) async throws -> OAuth2Grant``
    public func loginBiometric() async throws {
        let data = try await generateGrant(for: .biometric)
        
        do {
            self.signingData = data.securityData
            try await login(withGrant: data.grant)
        } catch {
            self.signingData = nil
        }
    }
    
    
    /// Create a cryptographic signature of a `Data` payload, using the security context from the last successful biometric login.
    ///
    /// Throws `.notAvailable` when there is no prior biometric login or the user's tokens have been revoked.
    ///
    /// Throws `.signing(Swift.Error)` when somwthing goes wrong with the actual signing process.
    public func signWithBiometricSecurityContext(
        _ data: Data,
        dataType: AuthorizationService.SecurityData.SignatureDataType = .message
    ) async throws(AuthorizationService.SecurityData.Error) -> (Data, counterPartDER: Data) {
        guard signingData != nil else {
            throw .notAvailable
        }
        
        
        let signarute = try await signingData!.sign(data, dataType: dataType)
        let publicDer = try await signingData!.extractPublicKeyDER()
        
        return (signarute, counterPartDER: publicDer)
    }
    
    
    /// Try login with any `OAuth2Grant`
    ///
    /// *login...* methods, **store** the relevant token response .
    public func login(withGrant grant: OAuth2Grant) async throws {
        let final = grant
            .with(client: client)
            .with(deviceIds: thisDeviceRepository.ids)
        
        tokenStorage.parse(try await authRepository.authorize(grant: final))
    }
    
    
    /// Based on [Rich Authorization Request RFC 9396](https://datatracker.ietf.org/doc/html/rfc9396).
    /// Generate a token that authorises the usage of a resource demanded by a request witch resulted in the `ExtendedProblemDetails`.
    ///
    /// - Params:
    /// - authorizationDetails: The value of the "authorization_details" property o
    public func tokenFor(authorizationDetails details: AuthorizationDetails, withGrant grant: OAuth2Grant) async throws -> TokenResponse {
        let final = grant
            .with(client: client)
            .with(deviceIds: thisDeviceRepository.ids)
            .with(authorizationDetails: String(data: details.value, encoding: .utf8)!)
        
        return try await authRepository.authorize(grant: final)
    }
    
    
    /// Try to refresh current token
    public func refreshTokens() async throws {
        guard let refresh = tokenStorage.refreshToken else {
            throw errorOfType(.authorization(error: .refreshTokenMissing))
        }
        
        try await login(withGrant: .refreshToken(with: refresh.value))
    }
    
    
    /// Request to revoke a use's access & refresh tokens.
    /// **access_token can be revoked only if it is a reference token**.
    public func revokeTokens() async throws {
        self.signingData = nil
        let accessToken  = tokenStorage.accessToken
        let refreshToken = tokenStorage.refreshToken
        
        tokenStorage.clearTokens()
        
        if let accessToken {
            try await authRepository.revoke(token: accessToken,
                                            withBasicAuth: client.basicAuth)
        }
        
        if let refreshToken {
            try await authRepository.revoke(token: refreshToken,
                                            withBasicAuth: client.basicAuth)
        }
    }
      
    /// Create a prepared URL pointing to the authentication's proper endpoint in order to initiate an "Authorization Code" flow.
    /// acr\_values, and ui\_locales are omitted as they can me appended by the consumer manually.
    public func authorizationUrl(withPkce pkce: PKCE) throws -> URL {
        try authorizationUrl(withPkce: pkce, andPrompt: "login")
    }
    
    /// Create a prepared URL pointing to the authentication's proper endpoint in order to initiate an "Authorization Code" flow.
    /// acr\_values, and ui\_locales are omitted as they can me appended by the consumer manually.
    nonisolated
    public func authorizationUrl(withPkce pkce: PKCE, andPrompt prompt: String) throws -> URL {
        let url = configuration.authorizationEndpoint
        
        guard let redirectUri = client.urls?.authorization else {
            throw errorOfType(.url(malformedUrl: configuration.authorizationEndpoint.absoluteString))
        }
        
        let queryParams = ["client_id"      : client.id,
                           "client_secret"  : client.secret,
                           "scope"          : client.userScope.value,
                           "redirect_uri"   : redirectUri,
                           "response_type"  : configuration.authCodeResponseType,
                           "response_mode"  : configuration.authCodeResponseMode,
                           "prompt"         : prompt,
                           "nonce"          : pkce.nonce,
                           "code_challenge" : pkce.challenge,
                           "code_challenge_method": pkce.challengeMethod.rawValue]
                               .compactMapValues { $0 }
        
        // ACR value could be added on the URL object manually if needed!
        // Localization "ui_locales"
        
        let paramsAsQueryParams: [URLQueryItem] = queryParams.map {
            .init(name: $0.key, value: $0.value)
        }

        return try url.appendingQueryItems(paramsAsQueryParams)
    }
    
    public func endSessionUrl() throws -> URL {
        var url = configuration.logoutEndpoint
        
        guard let postLogout = client.urls?.postLogout else {
            throw errorOfType(.url(malformedUrl: configuration.logoutEndpoint.absoluteString))
        }
        
        let queryParams: [URLQueryItem] = [
            .init(name: "id_token_hint",            value: tokenStorage.idToken),
            .init(name: "post_logout_redirect_uri", value: postLogout)]
        
        try url.appendQueryItems(queryParams)
        
        return url
    }
    
    internal func updateSecurityData(_ data: SecurityData?) {
        self.signingData = data
    }
    
}

private extension AuthorizationService {
    
    func keyOrThrow(locked: Bool, tagged tag: CryptoUtils.TagData? = nil) throws -> KeyPair {
        switch CryptoUtils.loadKeyPair(locked: locked, tagged: tag) {
        case .value(let pair): return pair
        case .error(let code):
            if code == errSecUserCanceled {
                throw errorOfType(.biometric(error: .userCanceled))
            } else {
                throw errorOfType(.biometric(error: .dataMissing))
            }
        }
    }
}



public struct DeviceGrantData: ~Copyable {
    public let grant: DeviceAuthenticationGrant
    let securityData: AuthorizationSecurityData?
}

public actor AuthorizationSecurityData {
    public enum Error: Swift.Error {
        case signing(error: Swift.Error?)
        case notAvailable
    }
    
    public enum SignatureDataType: Sendable {
        case message, digest
        
        internal var algorithm: SecKeyAlgorithm {
            switch self {
            case .message: .rsaSignatureMessagePKCS1v15SHA256
            case .digest : .rsaSignatureDigestPKCS1v15SHA256
            }
        }
    }
    
    private let key: SecKey
    
    init(key: SecKey) { self.key = key }
    
    internal func extractPublicKeyDER() async throws(Error) -> Data {
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            throw Error.notAvailable
        }
        var error: Unmanaged<CFError>? = nil
        guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw Error.signing(error: error?.takeRetainedValue())
        }
        
        return data
    }
    
    public func sign(_ data: Data, dataType: SignatureDataType) async throws(Error) -> Data {
        var error: Unmanaged<CFError>? = nil
        let result = SecKeyCreateSignature(key, dataType.algorithm, data as CFData, &error)
        
        guard let signatureData = result as Data? else {
            throw Error.signing(error: error?.takeRetainedValue())
        }
        
        return signatureData
    }
}


fileprivate extension CryptoUtils.KeyResult {
    var pair: KeyPair? {
        switch self {
        case .value(let pair): pair
        default: nil
        }
    }
    
    var error: OSStatus? {
        switch self {
        case .error(let code): code
        default: nil
        }
    }
}


internal protocol AuthorizationSecurityDataHolder: Actor {
    var signingData: AuthorizationSecurityData? { get set }
}

