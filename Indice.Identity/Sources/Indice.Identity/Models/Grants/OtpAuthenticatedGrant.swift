//
//  OtpAuthenticatedGrant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 29/3/23.
//

import Foundation


public struct OtpAuthenticatedGrant: OAuth2Grant {
    
    static public let grantType: String = "otp_authenticate"
    
    public struct Data {
        public let token: String
        public var otp: String? = nil
        public var channel: TotpDeliveryChannel? = nil
    }
    
    private let client : Client
    private let data   : Data
    
    public init(client: Client, data: Data) {
        self.client = client
        self.data   = data
    }
        
    public var params: Params {
        ["grant_type"    : Self.grantType,
         "otp"           : data.otp,
         "token"         : data.token,
         "channel"       : data.channel?.rawValue,
         "client_id"     : client.id,
         "scope"         : client.scope,
         "client_secret" : client.secret]
            .compactMapValues { $0 }
    }
}


extension OAuth2Grant where Self == OtpAuthenticatedGrant {
    
    static func otpAuthenticate(for client: Client, withData data: Self.Data) -> OtpAuthenticatedGrant{
        OtpAuthenticatedGrant(client: client, data: data)
    }
    
}
