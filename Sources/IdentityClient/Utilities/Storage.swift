//
//  Storage.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

/** A token storage that keeps its values only as long as the instance exists. */
public actor EphemeralTokenStorage: TokenStorage {
    private var response: TokenResponse?
    
    public init() { }
    
    public var idToken: String? {
        response?.id_token
    }
    
    public var refreshToken: TokenType? {
        guard let refreshToken = response?.refresh_token else { return nil }
        return .refreshToken(value: refreshToken)
    }
    
    public var accessToken: TokenType? {
        guard let accessToken = response?.access_token else { return nil }
        return .accessToken(value: accessToken)
    }
    
    public var tokenType: String? {
        response?.token_type
    }
    
    public func parse(_ response: TokenResponse) {
        self.response = response
    }

    public func clearTokens() {
        response = nil
    }
}

public extension TokenStorage where Self == EphemeralTokenStorage {
    /** A token storage that keeps its values only as long as the instance exists. */
    static var ephemeral: any TokenStorage { EphemeralTokenStorage() }
}
