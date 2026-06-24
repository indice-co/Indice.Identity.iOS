//
//  ServiceHub.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 3/11/25.
//

import Foundation


public final class ServiceHub: Sendable {
    
    internal let authRepository: AuthRepository
    internal let accountRepository: MyAccountRepository
    internal let devicesRepository: DevicesRepository
    internal let userRepository: UserInfoRepository
    internal let thisDeviceRepository: ThisDeviceRepository
    
    let processor: RequestProcessorWrapper
    let authorizationService: AuthorizationService
    let accountService: AccountService
    let devicesService: DevicesService
    let userService: UserService
    let registrationService: UserRegistrationService
    
    init(
        processorBuilder: @escaping @Sendable () -> RequestProcessor,
        configuration: IdentityClient.Configuration,
        options: IdentityClient.Options,
        storage: ValueStorage,
        secureStorage: SecureStorage,
        deviceInfo: CurrentDeviceInfoProvider,
        tokenStorage: TokenStorage,
        client: Client,
        errorParser: ErrorParser,
    ) {
        let processor = RequestProcessorWrapper(
            processor: processorBuilder(),
            tokenAccessor: tokenStorage)
        let authRepository = DefaultRepositoryFactory.authRepository(
            configuration: configuration,
            requestProcessor: processor)
        let accountRepository = DefaultRepositoryFactory.myAccountRepository(
            configuration: configuration,
            requestProcessor: processor)
        let devicesRepository = DefaultRepositoryFactory.devicesRepository(
            configuration: configuration,
            requestProcessor: processor)
        let userRepository = DefaultRepositoryFactory.userRepository(
            configuration: configuration,
            requestProcessor: processor)
        let thisDeviceRepository = DefaultRepositoryFactory.thisDeviceRepository(
            storage: storage,
            secureStorage: secureStorage,
            currentDeviceInfoProvider: deviceInfo)
        let authorizationService = AuthorizationService(
            authRepository: authRepository,
            accountRepository: accountRepository,
            devicesRepository: devicesRepository,
            thisDeviceRepository: thisDeviceRepository,
            tokenStorage: tokenStorage,
            client: client,
            configuration: configuration)
        
        self.processor = processor
        self.authRepository = authRepository
        self.accountRepository = accountRepository
        self.devicesRepository = devicesRepository
        self.userRepository = userRepository
        self.thisDeviceRepository = thisDeviceRepository
        self.authorizationService = authorizationService
        self.accountService = AccountService(accountRepository: accountRepository)
        self.devicesService = DevicesService(
            identityOptions: options,
            authorizationService: authorizationService,
            thisDeviceRepository: thisDeviceRepository,
            devicesRepository: devicesRepository,
            valueStorage: storage,
            secureStorage: secureStorage,
            errorParser: errorParser,
            client: client)
        self.userService = UserService(userRepository: userRepository)
        self.registrationService = UserRegistrationService(
            accountRepository: accountRepository,
            errorParser: errorParser)
    }
}
