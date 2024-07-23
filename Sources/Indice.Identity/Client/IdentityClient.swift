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
    typealias Errors  = IdentityClientErrors
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


/** A list  of ``APIError``s that the ``IdentityClient`` might throw. */
public struct IdentityClientErrors {
    private init() {}
    
    /** Thrown when the url starting the authorization\_code flow in malformed.  */
    public static let AuthUrl     = APIError(description: "Authorization endpoint url is invalid", code: nil)
    /** Thrown when trying starting a device\_authentication grand without a registration\_id present. */
    public static let TrustDevice = APIError(description: "Trust device registration not present", code: nil)
    /** Thrown when trying making a device trusted, but the max amount of trusted devices is reached for the user. */
    public static let TrustSwap   = APIError(description: "Another device has the trusted status", code: nil)
    /** Thrown when a grand has malformed params. Sanitize your inputs! */
    public static let Params      = APIError(description: "Query parameters are malformed",        code: nil)
    /** Thrown when an authorization with biometric/4pin doesn't find the necessary crypto keys, probably the device is not setup for device\_authentication */
    public static let SecKeys     = APIError(description: "SecKeys are not available",             code: nil)
    
    /* TODO: Comment */
    public static var UserCancel  = APIError(description: "User canceled",                         code: nil)
    
    /* TODO: Comment */
    public static let ServiceUnavailable = APIError(description: "Service unavailable",            code: nil)
}
