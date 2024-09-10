//
//  IdentityClientImplementation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/9/23.
//

import Foundation

private class Repositories {
    
    private let repositoryFactory: RepositoryFactory.Type
    private let configuration: IdentityConfig
    private let requestProcessor: RequestProcessor
    private let valueStorage: ValueStorage
    private let currentDeviceInfoProvider: CurrentDeviceInfoProvider

    init(repositoryFactory: RepositoryFactory.Type, 
         configuration: IdentityConfig,
         requestProcessor: RequestProcessor,
         valueStorage: ValueStorage,
         currentDeviceInfoProvider: CurrentDeviceInfoProvider) {
        self.repositoryFactory = repositoryFactory
        self.configuration = configuration
        self.requestProcessor = requestProcessor
        self.valueStorage = valueStorage
        self.currentDeviceInfoProvider = currentDeviceInfoProvider
    }
    
    internal lazy
    var authRepository: AuthRepository = {
        repositoryFactory.authRepository(configuration: configuration,
                                         requestProcessor: requestProcessor)
    }()
    
    internal lazy
    var accountRepository: MyAccountRepository = {
        repositoryFactory.myAccountRepository(configuration: configuration,
                                              requestProcessor: requestProcessor)
    }()
    
    internal lazy
    var devicesRepository: DevicesRepository = {
        repositoryFactory.devicesRepository(configuration: configuration,
                                            requestProcessor: requestProcessor)
    }()
    
    internal lazy
    var userRepository: UserInfoRepository = {
        repositoryFactory.userRepository(configuration: configuration,
                                         requestProcessor: requestProcessor)
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
    private  let options                   : IdentityClient.Options
    
    public var tokens: TokenStorageAccessor { get { tokenStorage } }

    private let networkOptionsBuilder: (IdentityClient) -> NetworkOptions
    private lazy var networkOptions: NetworkOptions = networkOptionsBuilder(self)
    
    private(set)
    lazy var requestProcessor: any RequestProcessor = {
        networkOptions.processor()
    }()
    
    private(set)
    lazy var networkClient: RequestProcessor = {
        RequestProcessorWrapper(processor: requestProcessor,
                                tokenAccessor: tokenStorage)
    }()
    
    private(set)
    lazy var errorParser: ErrorParser = networkOptions.errorParser
    
    private lazy
    var repositories: Repositories = {
       Repositories(repositoryFactory: DefaultRepositoryFactory.self,
                    configuration: configuration,
                    requestProcessor: networkClient,
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
        DevicesServiceImpl(identityOptions: options,
                           thisDeviceRepository: repositories.thisDeviceRepository,
                           devicesRepository: repositories.devicesRepository,
                           valueStorage: valueStorage,
                           client: client)
    }()
    
    
    public
    private(set)
    lazy var userRegistrationService: UserRegistrationService = {
        UserRegistrationServiceImpl(accountRepository: repositories.accountRepository,
                                    errorParser: errorParser)
    }()
    
    
    // MARK: - Init
    public init(client: Client,
                configuration: IdentityConfig,
                options: IdentityClient.Options = .init(maxTrustedDevicesCount: 1),
                currentDeviceInfoProvider: CurrentDeviceInfoProvider,
                valueStorage: ValueStorage = UserDefaults.standard,
                tokenStorage: TokenStorage = .ephemeral,
                networkOptionsBuilder: @escaping ((IdentityClient) -> NetworkOptions)) {
        self.client = client
        self.configuration = configuration
        self.currentDeviceInfoProvider = currentDeviceInfoProvider
        self.valueStorage = valueStorage
        self.tokenStorage = tokenStorage
        self.options = options
        self.networkOptionsBuilder = networkOptionsBuilder
    }
    
}
