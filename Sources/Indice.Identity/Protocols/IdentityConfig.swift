//
//  Authorization.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation


/** AuthorizationEndpoint describes basic properties regarding an Identity Authorization Server.   */
public struct IdentityConfig {

    /** Endpoints for trusting device (biometrics/4pin) */
    public struct DeviceTrustEndpoint {
        public let initializeEndpoint : String
        public let completionEndpoint : String
        public let authorizeEndpoint  : String
        
        public init(initializeEndpoint: String, completionEndpoint: String, authorizeEndpoint: String) {
            self.initializeEndpoint = initializeEndpoint
            self.completionEndpoint = completionEndpoint
            self.authorizeEndpoint  = authorizeEndpoint
        }
    }
    
    /** The base url of your identity server */
    var baseUrl               : String
    var authorizationEndpoint : String

    var tokenEndpoint         : String
    var revokeEndpoint        : String
    var logoutEndpoint        : String

    var authCodeResponseType  : String
    var authCodeResponseMode  : String
    var deviceRegistration    : DeviceTrustEndpoint

    public init(baseUrl: String,
                authorizationEndpoint: String,
                tokenEndpoint: String,
                revokeEndpoint: String, 
                logoutEndpoint: String,
                authCodeResponseType: String,
                authCodeResponseMode: String,
                deviceRegistration: DeviceTrustEndpoint) {
        self.baseUrl = baseUrl
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.revokeEndpoint = revokeEndpoint
        self.logoutEndpoint = logoutEndpoint
        self.authCodeResponseType = authCodeResponseType
        self.authCodeResponseMode = authCodeResponseMode
        self.deviceRegistration = deviceRegistration
    }
    
    public init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.authorizationEndpoint = "\(baseUrl)/connect/authorize"
        self.tokenEndpoint         = "\(baseUrl)/connect/token"
        self.revokeEndpoint        = "\(baseUrl)/connect/revocation"
        self.logoutEndpoint        = "\(baseUrl)/connect/endsession"
                
        self.authCodeResponseType  = "code"
        self.authCodeResponseMode  = "query"
        
        self.deviceRegistration = .init(initializeEndpoint : "\(baseUrl)/my/devices/register/init",
                                        completionEndpoint : "\(baseUrl)/my/devices/register/complete",
                                        authorizeEndpoint  : "\(baseUrl)/my/devices/connect/authorize")
    }
    
}
