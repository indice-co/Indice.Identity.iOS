//
//  OAuth2Grant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation


public struct ClientCredentialsGrant: OAuth2Grant {
    public static let grantType: String = "client_credentials"
    
    public var params: Params {
        ["grant_type": Self.grantType,
         "scope": "identity"]
            .compactMapValues { $0 }
    }
    
    public init() {}
    
    public let isUserGrant: Bool = false
}

public extension OAuth2Grant where Self == ClientCredentialsGrant {
    static func clientCredentials() -> ClientCredentialsGrant {
        ClientCredentialsGrant()
    }
}






