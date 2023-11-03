//
//  IdentityClientImplementation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/9/23.
//

import Foundation
import IndiceNetworkClient

private class Repositories {
    
    private let repositoryFactory: RepositoryFactory.Type
    private let configuration: IdentityConfig
    private let networkClient: NetworkClient
    private let valueStorage: ValueStorage
    private let currentDeviceInfoProvider: CurrentDeviceInfoProvider

    init(repositoryFactory: RepositoryFactory.Type, 
         configuration: IdentityConfig,
         networkClient: NetworkClient,
         valueStorage: ValueStorage,
         currentDeviceInfoProvider: CurrentDeviceInfoProvider) {
        self.repositoryFactory = repositoryFactory
        self.configuration = configuration
        self.networkClient = networkClient
        self.valueStorage = valueStorage
        self.currentDeviceInfoProvider = currentDeviceInfoProvider
    }
    
    internal lazy
    var authRepository: AuthRepository = {
        repositoryFactory.authRepository(configuration: configuration,
                                         networkClient: networkClient)
    }()
    
    internal lazy
    var accountRepository: MyAccountRepository = {
        repositoryFactory.myAccountRepository(configuration: configuration,
                                              networkClient: networkClient)
    }()
    
    internal lazy
    var devicesRepository: DevicesRepository = {
        repositoryFactory.devicesRepository(configuration: configuration,
                                            networkClient: networkClient)
    }()
    
    internal lazy
    var userRepository: UserInfoRepository = {
        repositoryFactory.userRepository(configuration: configuration,
                                         networkClient: networkClient)
    }()
    
    internal lazy
    var thisDeviceRepository: ThisDeviceRepository = {
        repositoryFactory.thisDeviceRepository(storage: valueStorage,
                                               currentDeviceInfoProvider: currentDeviceInfoProvider)
    }()
}

internal class IdentityClientImpl: IdentityClient {
    
    internal let client                    : Client
    internal let configuration             : IdentityConfig
    internal let tokenStorage              : TokenStorage
    private  let valueStorage              : ValueStorage
    private  let currentDeviceInfoProvider : CurrentDeviceInfoProvider
    
    public var tokens: TokenStorageAccessor { get { tokenStorage } }

    private let createNetworkClient: (IdentityClient) -> NetworkClient
    
    public
    private(set) lazy
    var networkClient: NetworkClient = {
        self.createNetworkClient(self)
    }()
    
    private lazy
    var repositories: Repositories = {
       Repositories(repositoryFactory: DefaultRepositoryFactory.self,
                    configuration: configuration,
                    networkClient: networkClient,
                    valueStorage: valueStorage,
                    currentDeviceInfoProvider: currentDeviceInfoProvider)
    }()
    
    // MARK: - Services
    
    public
    private(set) lazy
    var authorizationService: AuthorizationService = {
        AuthorizationServiceImpl(authRepository: repositories.authRepository,
                                 accountRepository: repositories.accountRepository,
                                 deviceRepository: repositories.devicesRepository,
                                 thisDeviceRepository: repositories.thisDeviceRepository,
                                 tokenStorage: tokenStorage,
                                 client: client,
                                 configuration: configuration)
    }()

    public
    private(set) lazy
    var userService: UserService = {
        UserServiceImpl(userRepository: repositories.userRepository)
    }()
    
    public
    private(set) lazy
    var accountService: AccountService = {
        AccountServiceImpl(accountRepository: repositories.accountRepository,
                           userService: userService)
    }()
    
    public
    private(set) lazy
    var devicesService: DevicesService = {
        DevicesServiceImpl(thisDeviceRepository: repositories.thisDeviceRepository,
                           devicesRepository: repositories.devicesRepository,
                           valueStorage: valueStorage,
                           client: client)
    }()
    
    
    public
    private(set)
    lazy var userRegistrationService: UserRegistrationService = {
        UserRegistrationServiceImpl(accountRepository: repositories.accountRepository)
    }()
    
    
    // MARK: - Init
    public init(client: Client,
                configuration: IdentityConfig,
                currentDeviceInfoProvider: CurrentDeviceInfoProvider,
                valueStorage: ValueStorage = UserDefaults.standard,
                tokenStorage: TokenStorage = .ephemeral,
                networkClientBuilder: ((IdentityClient) -> NetworkClient)? = nil) {
        self.client = client
        self.configuration = configuration
        self.currentDeviceInfoProvider = currentDeviceInfoProvider
        self.valueStorage = valueStorage
        self.tokenStorage = tokenStorage
        self.createNetworkClient = networkClientBuilder ?? { client in
            NetworkClient(interceptors: [AuthorizationHeaderInterceptor(tokenAccessor: client.tokens),
                                         AuthorizingInterceptor(authServiceProvider: { [weak client] in client?.authorizationService })])
        }
    }
    
}
