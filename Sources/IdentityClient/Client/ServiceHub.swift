//
//  ServiceHub.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 3/11/25.
//

import Foundation


public final class ServiceHub: @unchecked Sendable {
    
    private var authorization: AuthorizationService!
    private var account: AccountService!
    private var devices: DevicesService!
    private var user: UserService!
    private var userRegistration: UserRegistrationService!
    
    private let requestProcessor: RequestProcessor
    private let configuration: IdentityClient.Configuration
    private let options: IdentityClient.Options
    private let errorParser: ErrorParser
    
    private let storage: ValueStorage
    private let secureStorage: SecureStorage
    private let tokenStorage: TokenStorage
    private let deviceInfo: CurrentDeviceInfoProvider
    private let client: Client
    
    
    init(
        requestProcessor: RequestProcessor,
        configuration: IdentityClient.Configuration,
        options: IdentityClient.Options,
        storage: ValueStorage,
        secureStorage: SecureStorage,
        deviceInfo: CurrentDeviceInfoProvider,
        tokenStorage: TokenStorage,
        client: Client,
        errorParser: ErrorParser,
    ) {
        self.requestProcessor = requestProcessor
        self.configuration    = configuration
        self.options          = options
        self.storage          = storage
        self.secureStorage    = secureStorage
        self.tokenStorage     = tokenStorage
        self.deviceInfo       = deviceInfo
        self.client           = client
        self.errorParser      = errorParser
    }
    
    internal lazy
    var authRepository: AuthRepository = {
        DefaultRepositoryFactory.authRepository(
            configuration: configuration,
            requestProcessor: requestProcessor)
    }()
    
    internal lazy
    var accountRepository: MyAccountRepository = {
        DefaultRepositoryFactory.myAccountRepository(
            configuration: configuration,
            requestProcessor: requestProcessor)
    }()
    
    internal lazy
    var devicesRepository: DevicesRepository = {
        DefaultRepositoryFactory.devicesRepository(
            configuration: configuration,
            requestProcessor: requestProcessor)
    }()
    
    internal lazy
    var userRepository: UserInfoRepository = {
        DefaultRepositoryFactory.userRepository(
            configuration: configuration,
            requestProcessor: requestProcessor)
    }()
    
    internal lazy
    var thisDeviceRepository: ThisDeviceRepository = {
        DefaultRepositoryFactory.thisDeviceRepository(
            storage: storage,
            secureStorage: secureStorage,
            currentDeviceInfoProvider: deviceInfo)
    }()
    
    
    @ServicesActor
    func authorizationService() -> AuthorizationService {
        if authorization == nil {
            self.authorization = .init(
                authRepository: authRepository,
                accountRepository: accountRepository,
                devicesRepository: devicesRepository,
                thisDeviceRepository: thisDeviceRepository,
                tokenStorage: tokenStorage,
                client: client,
                configuration: configuration)
        }
        
        return authorization
    }
    
    @ServicesActor
    func accountService() -> AccountService {
        if account == nil {
            account = .init(accountRepository: accountRepository)
        }
        
        return account
    }
    
    @ServicesActor
    func devicesService() -> DevicesService {
        if devices == nil {
            devices = .init(
                identityOptions: options,
                serviceProvider: self,
                thisDeviceRepository: thisDeviceRepository,
                devicesRepository: devicesRepository,
                valueStorage: storage,
                client: client)
        }
        
        return devices
    }
    
    @ServicesActor
    func userService() -> UserService {
        if user == nil {
            user = .init(userRepository: userRepository)
        }
        
        return user
    }
    
    @ServicesActor
    func registrationService() -> UserRegistrationService {
        if userRegistration == nil {
            userRegistration = .init(
                accountRepository: accountRepository,
                errorParser: errorParser)
        }
        
        return userRegistration
    }
}

@globalActor
public final actor ServicesActor {
    public static let shared = ServicesActor()
}
