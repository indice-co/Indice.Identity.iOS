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
    typealias Errors = IdentityClientErrors
    
    var tokens: TokenStorageAccessor { get }
    var networkClient: NetworkClient { get }
    
    var authorizationService      : AuthorizationService      { get }
    var userService               : UserService               { get }
    var accountService            : AccountService            { get }
    var devicesService            : DevicesService            { get }
    var userRegistrationService   : UserRegistrationService   { get }
    var deviceRegistrationService : DeviceRegistrationService { get }
}


/**
 Create an instance of the IdentityClient.
 */
public class IdentityClientFactory {
    @available(*, unavailable)
    private init() {}
    
    
    /**
     Create an instance of the IdentityClient.
     
     - Parameter client: The Client info as set in the `IdentityServer`
     - Parameter configuration: Properties regarding the `IdentityServer` installation
     - Parameter currentDeviceInfoProvider: Provide in implementation of the ``CurrentDeviceInfoProvider``
     - Parameter valueStorage: (optional) Provide a custom implementation of a persistent storage. Default is `UserDefaults.standard`.
     - Parameter tokenStorage: (optional) Provide a custom TokenStorage implementation. Default is `TokenStorage.ephemeral`.
     - Parameter networkClientBuilder: (optional but suggested) Provide a builder for a ``NetworkClient``. Mainly used to add interceptors that use the accessToken.
                                   By default the builder adds a ``AuthorizationHeaderInterceptor`` and ``AuthorizingInterceptor`` that add any existing
                                   access tokens from the TokenStorage as Authorization header and try requesting a valid access token when a 401 error code is found, respectively.
     */
    public static func create(
        client: Client,
        configuration: IdentityConfig,
        currentDeviceInfoProvider: CurrentDeviceInfoProvider,
        valueStorage: ValueStorage = UserDefaults.standard,
        tokenStorage: TokenStorage = .ephemeral,
        networkClientBuilder: ((IdentityClient) -> NetworkClient)? = nil) -> IdentityClient {
            IdentityClientImpl(
                client: client,
                configuration: configuration,
                currentDeviceInfoProvider: currentDeviceInfoProvider,
                valueStorage: valueStorage,
                tokenStorage: tokenStorage,
                networkClientBuilder: networkClientBuilder)
    }
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
    
    /** TODO comment */
    public static let ServiceUnavailable = APIError(description: "Service unavailable",            code: nil)
}
