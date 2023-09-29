//
//  RepositoryFactory.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation
import IndiceNetworkClient

public protocol RepositoryFactory {
    static func authRepository      (configuration: IdentityConfig, networkClient: NetworkClient) -> AuthRepository
    static func userRepository      (configuration: IdentityConfig, networkClient: NetworkClient) -> UserInfoRepository
    static func myAccountRepository (configuration: IdentityConfig, networkClient: NetworkClient) -> MyAccountRepository
    static func devicesRepository   (configuration: IdentityConfig, networkClient: NetworkClient) -> DevicesRepository
    static func thisDeviceRepository(storage: ValueStorage, currentDeviceInfoProvider: CurrentDeviceInfoProvider) -> ThisDeviceRepository
}

internal class DefaultRepositoryFactory: RepositoryFactory {
    
    public static func authRepository(configuration: IdentityConfig, networkClient: NetworkClient) -> AuthRepository {
        AuthRepositoryImpl(configuration: configuration, networkClient: networkClient)
    }
    
    public static func userRepository(configuration: IdentityConfig, networkClient: NetworkClient) -> UserInfoRepository {
        UserInfoRepositoryImpl(configuration: configuration, networkClient: networkClient)
    }
    
    public static func devicesRepository(configuration: IdentityConfig, networkClient: NetworkClient) -> DevicesRepository {
        DevicesRepositoryImpl(configuration: configuration, networkClient: networkClient)
    }
    
    public static func myAccountRepository(configuration: IdentityConfig, networkClient: NetworkClient) -> MyAccountRepository {
        MyAccountRepositoryImpl(configuration: configuration, networkClient: networkClient)
    }
    
    public static func thisDeviceRepository(storage: ValueStorage, currentDeviceInfoProvider: CurrentDeviceInfoProvider) -> ThisDeviceRepository {
        ThisDeviceRepositoryImpl(storage: storage, currentDeviceInfoProvider: currentDeviceInfoProvider)
    }
}
