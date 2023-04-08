//
//  IdentityClientLogin.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation
import IndiceNetworkClient

/** Protocol containing any login method available on the Identity server. */
public protocol IdentityClientLogin {
    /** Try login with any grant */
    func login(withGrant grant: OAuth2Grant) async throws
    
    /** Try login using the password grant */
    func login(username: String, password: String) async throws
    
    /** Try login using the device\_authentication grant - using the 4pin mode */
    func login(withPin: String) async throws
    
    /** Try login using the device\_authentication grant - using the fingerprint mode */
    func loginBiometric() async throws
    
    /** Try to refresh current token */
    func refreshTokens() async throws
    
    
    /**
        Request to revoke a use's access & refresh tokens.
        **access_token can be revoked only if it is a reference token**.
     */
    func revokeTokens() async throws
    
    
    /** Generate the url used to initiate a authorization\_code flow  */
    func authorizationUrl(withPkce pkce: PKCE, andPrompt prompt: String) throws -> URL
    
    /** Generate the url used to end a user's session  */
    func endSessionUrl() throws -> URL
}



extension IdentityClient: IdentityClientLogin {
    public typealias UserLogin = IdentityClientLogin
    
    public var userLoginService: UserLogin { self }
    
    public func login(withGrant grant: OAuth2Grant) async throws {
        tokenStorage.parse(try await authRepository.authorize(grant: grant))
        
        try await refreshUserInfo()
        try await refreshDevices()
        
    }
    
    public func login(username: String, password: String) async throws {
        try await login(withGrant: .password(username: username,
                                             password: password,
                                             client: client))
    }
    
    public func login(withPin pin: String) async throws {
        guard let keys = CryptoUtils.loadKeyPair(locked: false, tagged: .devicePin) else {
            throw IdentityClient.Errors.SecKeys
        }

        let ids = thisDeviceRepository.ids
        let pinHash = try CryptoUtils.prepare(pin: pin,
                                              withDeviceId: ids.device,
                                              and: keys)
        
        try await login(withGrant: .pin(pin: pinHash, deviceIds: ids, client: client))
    }
    
    public func loginBiometric() async throws {
        guard let keys = CryptoUtils.loadKeyPair(locked: false, tagged: .fingerprint) else {
            throw IdentityClient.Errors.SecKeys
        }
        
        let codeVerifier = CryptoRandom.uniqueId()
        let verifierHash = CryptoUtils.challenge(for: codeVerifier)
        let ids = thisDeviceRepository.ids
        
        let response = try await deviceRepository.authorize(authRequest: try .biometrictAuth(codeChallenge: verifierHash,
                                                                                          deviceIds: ids,
                                                                                          client: client))
        
        let signedChallenge = try CryptoUtils.sign(string: response.challenge, with: keys)
        let publicPem       = try CryptoUtils.pem(for: keys)

        try await login(withGrant: try .biometric(challenge: response.challenge,
                                                  codeSignature: signedChallenge,
                                                  codeVerifier: codeVerifier,
                                                  publicPem: publicPem,
                                                  deviceIds: ids,
                                                  client: client))
    }
    
    public func refreshTokens() async throws {
        guard let refresh = tokenStorage.refreshToken else {
            throw APIError.Unauthenticated
        }
        
        try await login(withGrant: .refreshToken(client, with: refresh.value))
    }
    
    public func revokeTokens() async throws {
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
    
}



public extension IdentityClient /* IdentityClientLogin - Auth code helpers */ {
    
    /** Create a prepared URL pointing to the authentication's proper endpoint in order to initiate an "Authorization Code" flow.
        acr\_values, and ui\_locales are omitted as they can me appended by the consumer manually.
     */
    func authorizationUrl(withPkce pkce: PKCE, andPrompt prompt: String = "login") throws -> URL {
        guard var url = URL(string: authorization.authorizationEndpoint) else {
            throw Errors.AuthUrl
        }
        
        let queryParams = ["client_id": client.id,
                           "client_secret": client.secret,
                           "scope": client.scope,
                           "redirect_uri": authorization.authCallbackUri,
                           "response_type": authorization.authCodeResponseType,
                           "response_mode": authorization.authCodeResponseMode,
                           "prompt": prompt,
                           // "state": nil, // Unused for now.
                           "nonce": pkce.nonce,
                           "code_challenge": pkce.challenge,
                           "code_challenge_method": pkce.challengeMethod.rawValue]
            .compactMapValues { $0 }
        
        // ACR value could be added on the URL object manually if needed!
        // Localization "ui_locales"
        
        let paramsAsQueryParams: [URLQueryItem] = queryParams.map {
            .init(name: $0.key, value: $0.value)
        }
        
        if #available(iOS 16.0, *) {
            url.append(queryItems: paramsAsQueryParams)
        } else {
            try url.appendQueryItems(paramsAsQueryParams)
        }
        
        return url
    }
    
    func endSessionUrl() throws -> URL {
        guard var url = URL(string: authorization.logoutEndpoint) else {
            throw Errors.AuthUrl
        }
        
        let queryParams: [URLQueryItem] = [
            .init(name: "id_token_hint",            value: tokenStorage.idToken),
            .init(name: "post_logout_redirect_uri", value: authorization.logoutCallbackUri)
        ]
        if #available(iOS 16.0, *) {
            url.append(queryItems: queryParams)
        } else {
            try url.appendQueryItems(queryParams)
        }
        
        return url
    }
    
}

