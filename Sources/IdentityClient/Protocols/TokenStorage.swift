//
//  TokenStorage.swift
//  Indice_Identity
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//

import Foundation


/**
 Access the stored tokens of an auth response.
 It exists only to stop consumers of the ``TokenStorage`` from
 */
public protocol TokenStorageAccessor: AnyObject {
    var idToken       : String?    { get }
    var refreshToken  : TokenType? { get }
    var accessToken   : TokenType? { get }
    var tokenType     : String?    { get }
}

/**
  Can parse a ``TokenResponse`` and store the tokens
 */
public protocol TokenStorage: TokenStorageAccessor {
    func parse(_ response: TokenResponse)
    func clearTokens()
}

public extension TokenStorageAccessor {
    
    /** The value of the Authorization header based on the ``TokenResponse`` parsed. */
    var authorization : String? {
        guard let accessToken, let tokenType else {
            return nil
        }
        
        return "\(tokenType) \(accessToken.value)"
    }
}
