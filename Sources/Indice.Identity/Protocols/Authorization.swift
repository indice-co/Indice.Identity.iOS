//
//  Authorization.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

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


/** AuthorizationEndpoint describes basic properties regarding an Identity Authorization Server.   */
public protocol Authorization {
    
    typealias DeviceTrust = DeviceTrustEndpoint
    
    var baseUrl               : String      { get }
    var authorizationEndpoint : String      { get }
    var tokenEndpoint         : String      { get }
    var revokeEndpoint        : String      { get }
    var logoutEndpoint        : String      { get }
    var authCallbackUri       : String      { get }
    var logoutCallbackUri     : String      { get }
    var authCodeResponseType  : String      { get }
    var authCodeResponseMode  : String      { get }
    var deviceRegistration    : DeviceTrust { get }
    
}
