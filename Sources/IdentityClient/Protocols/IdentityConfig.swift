//
//  Authorization.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation


/** AuthorizationEndpoint describes basic properties regarding an Identity Authorization Server.   */
public struct IdentityConfig: Sendable {

    /** Endpoints for trusting device (biometrics/4pin) */
    public struct DeviceTrustEndpoint: Sendable {
        public let initialization : URL
        public let completion     : URL
        public let authorization  : URL
        
        public init(initializeEndpoint: String, completionEndpoint: String, authorizeEndpoint: String) throws {
            guard let initURL = URL(string: initializeEndpoint) else {
                throw IdentityClient.Error.url(malformedUrl: initializeEndpoint)
            }
            
            guard let compURL = URL(string: completionEndpoint) else {
                throw IdentityClient.Error.url(malformedUrl: completionEndpoint)
            }
            
            guard let authURL = URL(string: authorizeEndpoint) else {
                throw IdentityClient.Error.url(malformedUrl: authorizeEndpoint)
            }
            
            self.init(initializeEndpoint: initURL,
                      completionEndpoint: compURL,
                      authorizeEndpoint:  authURL)
        }
        
        public init(initializeEndpoint: URL, completionEndpoint: URL, authorizeEndpoint: URL) {
            self.completion     = completionEndpoint
            self.authorization  = authorizeEndpoint
            self.initialization = initializeEndpoint
        }
    }
    
    /** The base url of your identity server */
    var baseUrl               : URL
    var authorizationEndpoint : URL

    var tokenEndpoint         : URL
    var revokeEndpoint        : URL
    var logoutEndpoint        : URL

    var authCodeResponseType  : String
    var authCodeResponseMode  : String
    var deviceRegistration    : DeviceTrustEndpoint

    public init(baseUrl: URL,
                authorizationEndpoint: URL,
                tokenEndpoint: URL,
                revokeEndpoint: URL,
                logoutEndpoint: URL,
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
    
    public init(baseUrl: String) throws {
        guard let url = URL(string: baseUrl) else {
            throw IdentityClient.Error.url(malformedUrl: baseUrl)
        }
        
        self.init(baseUrl: url)
    }
    
    public init(baseUrl: URL) {
        self.baseUrl               = baseUrl
        self.authorizationEndpoint = baseUrl.appendingPathComponent("connect/authorize")
        self.tokenEndpoint         = baseUrl.appendingPathComponent("connect/token")
        self.revokeEndpoint        = baseUrl.appendingPathComponent("connect/revocation")
        self.logoutEndpoint        = baseUrl.appendingPathComponent("connect/endsession")
                
        self.authCodeResponseType  = "code"
        self.authCodeResponseMode  = "query"
        
        self.deviceRegistration = .init(initializeEndpoint : baseUrl.appendingPathComponent("my/devices/register/init"),
                                        completionEndpoint : baseUrl.appendingPathComponent("my/devices/register/complete"),
                                        authorizeEndpoint  : baseUrl.appendingPathComponent("my/devices/connect/authorize"))
    }    
}
