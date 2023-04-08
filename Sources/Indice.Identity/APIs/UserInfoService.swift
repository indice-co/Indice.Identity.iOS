//
//  UserInfoService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation
import IndiceNetworkClient

class UserInfoRepositoryImpl: UserInfoRepository {
    
    private let authorization: Authorization
    private let networkClient: NetworkClient
    
    init(authorization: Authorization, networkClient: NetworkClient) {
        self.authorization = authorization
        self.networkClient = networkClient
    }
    
    func userInfo() async throws -> UserInfo {
        let request = URLRequest.builder()
            .get(path: authorization.baseUrl + "/connect/userinfo")
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }
    
}
