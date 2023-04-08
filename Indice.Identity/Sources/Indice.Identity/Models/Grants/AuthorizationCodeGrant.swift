//
//  AuthorizationCodeGrant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

/** AuthorizationCodeGrant a grant used for the authorization code flow.  */
public struct AuthorizationCodeGrant: OAuth2Grant {
    public static let grantType: String = "authorization_code"
    
    public let code: String
    public let codeVerifier: String
    public let redirect_uri: String
    
    public let client: Client
    
    public var params: Params {
        ["grant_type" : Self.grantType,
         "client_id" : client.id,
         "scope" : client.scope,
         "code" : code,
         "code_verifier" : codeVerifier,
         "redirect_uri" : redirect_uri,
         "client_secret" : client.secret]
            .compactMapValues { $0 }
    }
    
    public init(code: String, codeVerifier: String, redirect_uri: String, client: Client) {
        self.code = code
        self.codeVerifier = codeVerifier
        self.redirect_uri = redirect_uri
        self.client = client
    }

}

public extension OAuth2Grant where Self == AuthorizationCodeGrant {
    static func authCode(code: String, codeVerifier: String, redirectUri: String, client: Client) -> AuthorizationCodeGrant {
        AuthorizationCodeGrant(code: code, codeVerifier: codeVerifier, redirect_uri: redirectUri, client: client)
    }
}
