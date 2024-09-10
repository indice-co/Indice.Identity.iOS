//
//  UserInfoService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation
import NetworkUtilities

class UserInfoRepositoryImpl: UserInfoRepository {
    
    private let configuration: IdentityConfig
    private let requestProcessor: RequestProcessor
    
    init(configuration: IdentityConfig, requestProcessor: RequestProcessor) {
        self.configuration = configuration
        self.requestProcessor = requestProcessor
    }
    
    func userInfo() async throws -> UserInfo {
        let request = URLRequest.builder()
            .get(path: configuration.baseUrl + "/connect/userinfo")
            .add(header: .accept(type: .json))
            .build()
        
        return try await requestProcessor.process(request: request)
    }
    
}
