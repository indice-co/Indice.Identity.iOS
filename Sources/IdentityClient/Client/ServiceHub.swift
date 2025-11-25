//
//  ServiceHub.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 3/11/25.
//

import Foundation


public final class ServiceHub: @unchecked Sendable {
    
    private let lock = CriticalSectionLock()
    private let builderLock = CriticalSectionLock()
    
    private var authorization: AuthorizationService!
    private var account: AccountService!
    private var devices: DevicesService!
    private var user: UserService!
    private var userRegistration: UserRegistrationService!
    
    private let processorBuilder: () -> RequestProcessor
    private let configuration: IdentityClient.Configuration
    private let options: IdentityClient.Options
    private let errorParser: ErrorParser
    
    private let storage: ValueStorage
    private let secureStorage: SecureStorage
    private let tokenStorage: TokenStorage
    private let deviceInfo: CurrentDeviceInfoProvider
    private let client: Client
    
    
    init(
        processorBuilder: @escaping () -> RequestProcessor,
        configuration: IdentityClient.Configuration,
        options: IdentityClient.Options,
        storage: ValueStorage,
        secureStorage: SecureStorage,
        deviceInfo: CurrentDeviceInfoProvider,
        tokenStorage: TokenStorage,
        client: Client,
        errorParser: ErrorParser,
    ) {
        self.processorBuilder = processorBuilder
        self.configuration    = configuration
        self.options          = options
        self.storage          = storage
        self.secureStorage    = secureStorage
        self.tokenStorage     = tokenStorage
        self.deviceInfo       = deviceInfo
        self.client           = client
        self.errorParser      = errorParser
    }
    
    private var requestProcessor: RequestProcessorWrapper!
    
    var processor: RequestProcessorWrapper {
        builderLock.withLock {
            if requestProcessor == nil {
                let wrapped = RequestProcessorWrapper(
                    processor: processorBuilder(),
                    tokenAccessor: tokenStorage)
                
                requestProcessor = wrapped
            }
            
            return requestProcessor
        }
    }
    
    internal lazy
    var authRepository: AuthRepository = {
        DefaultRepositoryFactory.authRepository(
            configuration: configuration,
            requestProcessor: processor)
    }()
    
    internal lazy
    var accountRepository: MyAccountRepository = {
        DefaultRepositoryFactory.myAccountRepository(
            configuration: configuration,
            requestProcessor: processor)
    }()
    
    internal lazy
    var devicesRepository: DevicesRepository = {
        DefaultRepositoryFactory.devicesRepository(
            configuration: configuration,
            requestProcessor: processor)
    }()
    
    internal lazy
    var userRepository: UserInfoRepository = {
        DefaultRepositoryFactory.userRepository(
            configuration: configuration,
            requestProcessor: processor)
    }()
    
    internal lazy
    var thisDeviceRepository: ThisDeviceRepository = {
        DefaultRepositoryFactory.thisDeviceRepository(
            storage: storage,
            secureStorage: secureStorage,
            currentDeviceInfoProvider: deviceInfo)
    }()
    
    
    var authorizationService: AuthorizationService {
        lock.withLock {
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
    }
    
    var accountService: AccountService {
        lock.withLock {
            if account == nil {
                account = .init(accountRepository: accountRepository)
            }
            
            return account
        }
    }
    
    var devicesService: DevicesService {
        lock.withLock {
            if devices == nil {
                devices = .init(
                    identityOptions: options,
                    serviceProvider: self,
                    thisDeviceRepository: thisDeviceRepository,
                    devicesRepository: devicesRepository,
                    valueStorage: storage,
                    secureStorage: secureStorage,
                    client: client)
            }
            
            return devices
        }
    }
    
    var userService: UserService {
        lock.withLock {
            if user == nil {
                user = .init(userRepository: userRepository)
            }
            
            return user
        }
    }
    
    var registrationService: UserRegistrationService {
        lock.withLock {
            if userRegistration == nil {
                userRegistration = .init(
                    accountRepository: accountRepository,
                    errorParser: errorParser)
            }
            
            return userRegistration
        }
    }
}
