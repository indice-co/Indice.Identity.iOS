//
//  AuthService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation
import NetworkUtilities

final class AuthRepositoryImpl: AuthRepository {
    
    private let configuration: IdentityConfig
    private let requestProcessor: RequestProcessor
    
    init(configuration: IdentityConfig, requestProcessor: RequestProcessor) {
        self.configuration = configuration
        self.requestProcessor = requestProcessor
    }
    
    func authorize(grant: OAuth2Grant) async throws -> TokenResponse {
        try await requestProcessor.fetch(request: .builder()
            .post(url: configuration.tokenEndpoint)
            .bodyFormUTF8(params: grant.params)
            .add(header: .accept(type: .json))
            .build())
        .item
    }

    func revoke(token: TokenType, withBasicAuth auth: String) async throws {
        let body = ["token": token.value, "tokenTypeHint": token.typeHint]
            .compactMapValues { $0 }
        
        let request = try URLRequest.builder()
            .post(url: configuration.revokeEndpoint)
            .bodyFormUTF8(params: body)
            .add(header: .accept(type: .json))
            .add(header: .authorization(auth: auth))
            .build()
        
        try await requestProcessor.fetch(request: request).item
    }
}
