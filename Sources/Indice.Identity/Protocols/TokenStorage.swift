//
//  TokenStorage.swift
//  Indice_Identity
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//

import Foundation

public protocol TokenStorageAccessor: AnyObject {
    var idToken       : String?    { get }
    var refreshToken  : TokenType? { get }
    var accessToken   : TokenType? { get }
    var tokenType     : String?    { get }
}

public protocol TokenStorage: TokenStorageAccessor {
    func parse(_ response: TokenResponse)
    func clearTokens()
}

public extension TokenStorageAccessor {
    var authorization : String? {
        guard let accessToken, let tokenType else {
            return nil
        }
        
        return "\(tokenType) \(accessToken.value)"
    }
}
