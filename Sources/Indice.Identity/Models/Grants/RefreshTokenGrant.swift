//
//  RefreshTokenGrant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public struct RefreshTokenGrant: OAuth2Grant {
    public static let grantType: String = "refresh_token"

    let refreshToken: String
    
    public var params: Params {
        ["grant_type": Self.grantType,
         "refresh_token": refreshToken]
            .compactMapValues { $0 }
    }
}

public extension OAuth2Grant where Self == RefreshTokenGrant {
    static func refreshToken(with refreshToken: String) -> RefreshTokenGrant {
        RefreshTokenGrant(refreshToken: refreshToken)
    }
}
