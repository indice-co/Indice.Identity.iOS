//
//  TokenResponse.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public struct TokenResponse: Codable {
    public let access_token: String
    public let expires_in: Int
    public let token_type: String
    public let scope: String
    public let refresh_token: String?
    public let id_token: String?
    
    public init(access_token: String, expires_in: Int, token_type: String, scope: String, refresh_token: String?, id_token: String?) {
        self.access_token = access_token
        self.expires_in = expires_in
        self.token_type = token_type
        self.scope = scope
        self.refresh_token = refresh_token
        self.id_token = id_token
    }
}

/** Default  */
public extension TokenResponse {
    var authorization: String { "\(token_type) \(access_token)" }
}
