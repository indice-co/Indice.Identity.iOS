//
//  OAuth2Grant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation


public struct ClientCredentialsGrant: OAuth2Grant {
    public static let grantType: String = "client_credentials"
    public let client: Client
    
    public var params: Params {
        ["grant_type": Self.grantType,
         "client_id": client.id,
         "client_secret": client.secret,
         "scope": "identity"]
            .compactMapValues { $0 }
    }
    
    public init(client: Client) {
        self.client = client
    }
}

public extension OAuth2Grant where Self == ClientCredentialsGrant {
    static func clientCredentials(_ client: Client) -> ClientCredentialsGrant {
        ClientCredentialsGrant(client: client)
    }
}






