//
//  IdentityClientImplementation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/9/23.
//

import Foundation

internal class Repositories {
    
    private let repositoryFactory: RepositoryFactory.Type
    private let configuration: IdentityConfig
    private let requestProcessor: RequestProcessor
    private let valueStorage: ValueStorage
    private let secureStorage: SecureStorage
    private let currentDeviceInfoProvider: CurrentDeviceInfoProvider
    private let errorParser: ErrorParser
    
    init(repositoryFactory: RepositoryFactory.Type,
         configuration: IdentityConfig,
         requestProcessor: RequestProcessor,
         valueStorage: ValueStorage,
         secureStorage: SecureStorage,
         errorParser: ErrorParser,
         currentDeviceInfoProvider: CurrentDeviceInfoProvider) {
        self.repositoryFactory = repositoryFactory
        self.configuration = configuration
        self.requestProcessor = requestProcessor
        self.valueStorage = valueStorage
        self.secureStorage = secureStorage
        self.errorParser = errorParser
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
                                               secureStorage: secureStorage,
                                               currentDeviceInfoProvider: currentDeviceInfoProvider)
    }()
}
