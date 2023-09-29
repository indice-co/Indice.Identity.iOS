//
//  AuthService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation
import IndiceNetworkClient


class AuthRepositoryImpl: AuthRepository {
    
    private let configuration: IdentityConfig
    private let networkClient: NetworkClient
    
    init(configuration: IdentityConfig, networkClient: NetworkClient) {
        self.configuration = configuration
        self.networkClient = networkClient
    }
    
    func authorize(grant: OAuth2Grant) async throws -> TokenResponse {
        let request = URLRequest.builder()
            .post(path: configuration.tokenEndpoint)
            .bodyFormUtf8(params: grant.params)
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }

    func revoke(token: TokenType, withBasicAuth auth: String) async throws {
        let body = ["token": token.value, "tokenTypeHint": token.typeHint]
            .compactMapValues { $0 }
        
        let request = URLRequest.builder()
            .post(path: configuration.revokeEndpoint)
            .bodyFormUtf8(params: body)
            .add(header: .accept(type: .json))
            .add(header: .authorisation(auth: auth))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
}
