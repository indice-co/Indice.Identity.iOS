//
//  RepositoryFactories.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation
import IndiceNetworkClient

public protocol RepositoryFactory {
    static func authRepository      (authorization: Authorization, networkClient: NetworkClient) -> AuthRepository
    static func userRepository      (authorization: Authorization, networkClient: NetworkClient) -> UserInfoRepository
    static func myAccountRepository (authorization: Authorization, networkClient: NetworkClient) -> MyAccountRepository
    static func devicesRepository   (authorization: Authorization, networkClient: NetworkClient) -> DevicesRepository
    static func thisDeviceRepository(storage: ValueStorage) -> ThisDeviceRepository
}

public class DefaultRepositoryFactory: RepositoryFactory {
    
    public static func authRepository(authorization: Authorization, networkClient: NetworkClient) -> AuthRepository {
        AuthRepositoryImpl(authorization: authorization, networkClient: networkClient)
    }
    
    public static func userRepository(authorization: Authorization, networkClient: NetworkClient) -> UserInfoRepository {
        UserInfoRepositoryImpl(authorization: authorization, networkClient: networkClient)
    }
    
    public static func devicesRepository(authorization: Authorization, networkClient: NetworkClient) -> DevicesRepository {
        DevicesRepositoryImpl(authorization: authorization, networkClient: networkClient)
    }
    
    public static func myAccountRepository(authorization: Authorization, networkClient: NetworkClient) -> MyAccountRepository {
        MyAccountRepositoryImpl(authorization: authorization, networkClient: networkClient)
    }
    
    public static func thisDeviceRepository(storage: ValueStorage) -> ThisDeviceRepository {
        ThisDeviceRepositoryImpl(storage: storage)
    }
}
