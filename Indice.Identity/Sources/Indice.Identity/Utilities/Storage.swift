//
//  Storage.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation


public class EphemeralTokenStorage: TokenStorage {
    
    public private(set) var idToken: String?
    public private(set) var refreshToken: TokenType?
    public private(set) var accessToken: TokenType?
    public private(set) var tokenType: String?
    
    public private(set) var authorization: String?
    
    public func parse(_ response: TokenResponse) {
        idToken = response.id_token
        tokenType = response.token_type
        accessToken = .accessToken(value: response.access_token)
        refreshToken = .refreshToken(value: response.refresh_token)
    }

    public func clearTokens() {
        tokenType = nil
        refreshToken = nil
        idToken = nil
        accessToken = nil
    }
}

public extension TokenStorage where Self == EphemeralTokenStorage {
    static var ephemeral: any TokenStorage { EphemeralTokenStorage() }
}
