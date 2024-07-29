//
//  IdentityClient.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//

import Foundation
import IndiceNetworkClient

/**
 The IdentityClient! Encapsulates and manages all the services provided by the Indice.AspNet Identity library that are relevant to a client application.
 One instance should be created.
 */
public protocol IdentityClient: AnyObject {
    typealias Error   = IdentityClientErrors
    typealias Options = IdentityClientOptions
    
    var tokens: TokenStorageAccessor    { get }
    var networkClient: RequestProcessor { get }
    
    var authorizationService      : AuthorizationService      { get }
    var userService               : UserService               { get }
    var accountService            : AccountService            { get }
    var devicesService            : DevicesService            { get }
    var userRegistrationService   : UserRegistrationService   { get }
}


public struct IdentityClientOptions {
    var maxTrustedDevicesCount: Int = 1
}

