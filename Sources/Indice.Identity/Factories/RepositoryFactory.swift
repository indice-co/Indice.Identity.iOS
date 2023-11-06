//
//  RepositoryFactory.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation
import IndiceNetworkClient

public protocol RepositoryFactory {
    static func authRepository      (configuration: IdentityConfig, requestProcessor: RequestProcessor) -> AuthRepository
    static func userRepository      (configuration: IdentityConfig, requestProcessor: RequestProcessor) -> UserInfoRepository
    static func myAccountRepository (configuration: IdentityConfig, requestProcessor: RequestProcessor) -> MyAccountRepository
    static func devicesRepository   (configuration: IdentityConfig, requestProcessor: RequestProcessor) -> DevicesRepository
    static func thisDeviceRepository(storage: ValueStorage, currentDeviceInfoProvider: CurrentDeviceInfoProvider) -> ThisDeviceRepository
}

internal class DefaultRepositoryFactory: RepositoryFactory {
    
    public static func authRepository(configuration: IdentityConfig, requestProcessor: RequestProcessor) -> AuthRepository {
        AuthRepositoryImpl(configuration: configuration, requestProcessor: requestProcessor)
    }
    
    public static func userRepository(configuration: IdentityConfig, requestProcessor: RequestProcessor) -> UserInfoRepository {
        UserInfoRepositoryImpl(configuration: configuration, requestProcessor: requestProcessor)
    }
    
    public static func devicesRepository(configuration: IdentityConfig, requestProcessor: RequestProcessor) -> DevicesRepository {
        DevicesRepositoryImpl(configuration: configuration, requestProcessor: requestProcessor)
    }
    
    public static func myAccountRepository(configuration: IdentityConfig, requestProcessor: RequestProcessor) -> MyAccountRepository {
        MyAccountRepositoryImpl(configuration: configuration, requestProcessor: requestProcessor)
    }
    
    public static func thisDeviceRepository(storage: ValueStorage, currentDeviceInfoProvider: CurrentDeviceInfoProvider) -> ThisDeviceRepository {
        ThisDeviceRepositoryImpl(storage: storage, currentDeviceInfoProvider: currentDeviceInfoProvider)
    }
}
