//
//  RefreshTokenGrant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public struct RefreshTokenGrant: OAuth2Grant {
    public static let grantType: String = "refresh_token"
    let client: Client
    let refreshToken: String
    
    public var params: Params {
        ["grant_type": Self.grantType,
         "client_id": client.id,
         "refresh_token": refreshToken,
         "client_secret": client.secret]
            .compactMapValues { $0 }
    }
}

public extension OAuth2Grant where Self == RefreshTokenGrant {
    static func refreshToken(_ client: Client, with refreshToken: String) -> RefreshTokenGrant {
        RefreshTokenGrant(client: client, refreshToken: refreshToken)
    }
}
