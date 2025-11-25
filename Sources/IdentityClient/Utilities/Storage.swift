//
//  Storage.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

/** A token storage that keeps its values only as long as the instance exists. */
final public class EphemeralTokenStorage: TokenStorage, @unchecked Sendable {
    
    private let lock: CriticalSectionLock = .init()
    
    public var idToken: String? {
        lock.withLock { response?.id_token }
    }
    public var refreshToken: TokenType? {
        lock.withLock { (response?.refresh_token)
            .map(TokenType.refreshToken) }
    }
    public var accessToken: TokenType? {
        lock.withLock { (response?.access_token)
            .map(TokenType.accessToken) }
    }
    public var tokenType: String? {
        lock.withLock { response?.token_type }
    }
        
    private var response: TokenResponse?
    
    public func parse(_ response: TokenResponse) {
        lock.withLock {
            self.response = response
        }
    }

    public func clearTokens() {
        lock.withLock {
            response = nil
        }
    }
}

public extension TokenStorage where Self == EphemeralTokenStorage {
    /** A token storage that keeps its values only as long as the instance exists. */
    static var ephemeral: any TokenStorage { EphemeralTokenStorage() }
}
