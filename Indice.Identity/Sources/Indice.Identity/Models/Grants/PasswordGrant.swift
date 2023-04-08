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
    
    public let client: Client
    
    public var params: Params {
        ["grant_type"    : Self.grantType,
         "client_id"     : client.id,
         "scope"         : client.scope,
         "username"      : username,
         "password"      : password,
         "client_secret" : client.secret]
            .compactMapValues { $0 }
    }
    
    public init(username: String, password: String, client: Client) {
        self.username = username
        self.password = password
        self.client = client
    }
}


public extension OAuth2Grant where Self == PasswordGrant {
    static func password(username: String, password: String, client: Client) -> PasswordGrant {
        PasswordGrant(username: username, password: password, client: client)
    }
}
