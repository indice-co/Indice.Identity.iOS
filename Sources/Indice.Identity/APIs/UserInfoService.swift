//
//  UserInfoService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation
import IndiceNetworkClient

class UserInfoRepositoryImpl: UserInfoRepository {
    
    private let configuration: IdentityConfig
    private let networkClient: NetworkClient
    
    init(configuration: IdentityConfig, networkClient: NetworkClient) {
        self.configuration = configuration
        self.networkClient = networkClient
    }
    
    func userInfo() async throws -> UserInfo {
        let request = URLRequest.builder()
            .get(path: configuration.baseUrl + "/connect/userinfo")
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }
    
}
