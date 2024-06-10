//
//  PasswordGrant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

/** Password flow grant. Used for user credentials login. */
public struct PasswordGrant: OAuth2Grant {
    static public let grantType: String = "password"
    
    public let username: String
    public let password: String
    
    public var params: Params {
        ["grant_type"    : grantType,
         "username"      : username,
         "password"      : password]
            .compactMapValues { $0 }
    }
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}


public extension OAuth2Grant where Self == PasswordGrant {
    static func password(username: String, password: String) -> PasswordGrant {
        PasswordGrant(username: username, password: password)
    }
}
