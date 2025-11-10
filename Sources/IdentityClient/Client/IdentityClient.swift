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
final public class IdentityClient: @unchecked Sendable {
    public typealias Error   = IdentityClientErrors
    public typealias Options = IdentityClientOptions
    public typealias Configuration = IdentityConfig

    internal let client                    : Client
    internal let configuration             : IdentityConfig
    internal let tokenStorage              : TokenStorage
    private  let valueStorage              : ValueStorage
    private  let secureStorage             : SecureStorage
    private  let currentDeviceInfoProvider : CurrentDeviceInfoProvider
    private  let options                   : IdentityClient.Options
    
    public let serviceHub: ServiceHub
    
    public var tokens: TokenStorageAccessor { get { tokenStorage } }

//    private let networkOptionsBuilder: @Sendable (IdentityClient) -> NetworkOptions
//    private lazy var networkOptions: NetworkOptions = networkOptionsBuilder(self)
//    
//    private var serviceProvider: ServiceProvider!
//    
//    
//    private(set)
//    lazy var requestProcessor: any RequestProcessor = {
//        networkOptions.processor()
//    }()
//    
//    private(set)
//    lazy var networkClient: RequestProcessor = {
//        RequestProcessorWrapper(processor: requestProcessor,
//                                tokenAccessor: tokenStorage)
//    }()
    
//    private(set)
//    lazy var errorParser: ErrorParser = networkOptions.errorParser
//    
//    private lazy
//    var repositories: Repositories = {
//       Repositories(repositoryFactory: DefaultRepositoryFactory.self,
//                    configuration: configuration,
//                    requestProcessor: networkClient,
//                    valueStorage: valueStorage,
//                    secureStorage: secureStorage,
//                    errorParser: errorParser,
//                    currentDeviceInfoProvider: currentDeviceInfoProvider)
//    }()
//    
//    // MARK: - Services
//    
//    public
//    private(set) lazy
//    var authorizationService: AuthorizationService = {
//        AuthorizationServiceImpl(authRepository: repositories.authRepository,
//                                 accountRepository: repositories.accountRepository,
//                                 deviceRepository: repositories.devicesRepository,
//                                 thisDeviceRepository: repositories.thisDeviceRepository,
//                                 tokenStorage: tokenStorage,
//                                 client: client,
//                                 configuration: configuration)
//    }()
//
//    public
//    private(set) lazy
//    var userService: UserService = {
//        UserServiceImpl(userRepository: repositories.userRepository)
//    }()
//    
//    public
//    private(set) lazy
//    var accountService: AccountService = {
//        AccountServiceImpl(accountRepository: repositories.accountRepository,
//                           userService: userService)
//    }()
//    
//    public
//    private(set) lazy
//    var devicesService: DevicesService = {
//        DevicesServiceImpl(identityOptions: options,
//                           serviceProvider: serviceProvider,
//                           thisDeviceRepository: repositories.thisDeviceRepository,
//                           devicesRepository: repositories.devicesRepository,
//                           valueStorage: valueStorage,
//                           client: client)
//    }()
//    
//    
//    public
//    private(set)
//    lazy var userRegistrationService: UserRegistrationService = {
//        UserRegistrationServiceImpl(accountRepository: repositories.accountRepository,
//                                    errorParser: errorParser)
//    }()
//    
//    
    // MARK: - Init
    public init(client: Client,
                configuration: IdentityConfig,
                options: IdentityClient.Options = .init(maxTrustedDevicesCount: 1),
                currentDeviceInfoProvider: CurrentDeviceInfoProvider,
                valueStorage: ValueStorage = UserDefaults.standard,
                secureStorage: SecureStorage = SecureStorage(),
                tokenStorage: TokenStorage = .ephemeral,
                networkOptionsBuilder: @Sendable @escaping () -> NetworkOptions) {
        self.client = client
        self.configuration = configuration
        self.currentDeviceInfoProvider = currentDeviceInfoProvider
        self.valueStorage = valueStorage
        self.secureStorage = secureStorage
        self.tokenStorage = tokenStorage
        self.options = options
        
        let built = networkOptionsBuilder()
        
        self.serviceHub = .init(
            requestProcessor: built.processor(),
            configuration: configuration,
            options: options,
            storage: valueStorage,
            secureStorage: secureStorage,
            deviceInfo: currentDeviceInfoProvider,
            tokenStorage: tokenStorage,
            client: client,
            errorParser: built.errorParser)
        // self.networkOptionsBuilder = networkOptionsBuilder
        // self.serviceProvider = .init { [weak self] in self }
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
