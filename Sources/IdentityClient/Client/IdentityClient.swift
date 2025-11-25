//
//  IdentityClient.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//

import Foundation


/**
 The IdentityClient! Encapsulates and manages all the services provided by the Indice.AspNet Identity library that are relevant to a client application.
 One instance should be created.
 */
final public class IdentityClient: Sendable {
    public typealias Error   = IdentityClientErrors
    public typealias Options = IdentityClientOptions
    public typealias Configuration = IdentityConfig
    
    public typealias Authorization = AuthorizationService
    public typealias User = UserService
    public typealias Devices = DevicesService
    public typealias Account = AccountService
    public typealias UserRegistration = UserRegistrationService
    

    internal let client                    : Client
    internal let configuration             : IdentityConfig
    internal let tokenStorage              : TokenStorage
    private  let valueStorage              : ValueStorage
    private  let secureStorage             : SecureStorage
    private  let currentDeviceInfoProvider : CurrentDeviceInfoProvider
    private  let options                   : IdentityClient.Options
    
    
    public var authService         : AuthorizationService    { serviceHub.authorizationService }
    public var userService         : UserService             { serviceHub.userService }
    public var devicesService      : DevicesService          { serviceHub.devicesService }
    public var accountService      : AccountService          { serviceHub.accountService }
    public var registrationService : UserRegistrationService { serviceHub.registrationService }
    
    private let serviceHub: ServiceHub
    
    public var requestProcessor: RequestProcessor { serviceHub.processor.processor }
    
    public var tokens: TokenStorageAccessor { get { tokenStorage } }
    
    
    // MARK: - Init
    public init(client          : Client,
                configuration   : IdentityConfig,
                options         : IdentityClient.Options = .init(maxTrustedDevicesCount: 1),
                currentDeviceInfoProvider: CurrentDeviceInfoProvider,
                valueStorage    : ValueStorage = UserDefaults.standard,
                secureStorage   : SecureStorage = SecureStorage(),
                tokenStorage    : TokenStorage = .ephemeral,
                networkOptions  : NetworkOptions) {
        self.client         = client
        self.configuration  = configuration
        self.valueStorage   = valueStorage
        self.secureStorage  = secureStorage
        self.tokenStorage   = tokenStorage
        self.options        = options
        self.currentDeviceInfoProvider = currentDeviceInfoProvider
        
        
        self.serviceHub = .init(
            processorBuilder: networkOptions.processorBuilder,
            configuration: configuration,
            options: options,
            storage: valueStorage,
            secureStorage: secureStorage,
            deviceInfo: currentDeviceInfoProvider,
            tokenStorage: tokenStorage,
            client: client,
            errorParser: networkOptions.errorParser)
    }
}


public struct IdentityClientOptions: Sendable {
    var maxTrustedDevicesCount: Int
    var userPersistantDeviceId: Bool
    
    public init(
        maxTrustedDevicesCount: Int  = 1,
        userPersistantDeviceId: Bool = false
    ) {
        self.maxTrustedDevicesCount = maxTrustedDevicesCount
        self.userPersistantDeviceId = userPersistantDeviceId
    }
}
