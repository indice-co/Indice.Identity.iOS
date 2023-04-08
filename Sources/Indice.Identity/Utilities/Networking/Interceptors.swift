//
//  Interceptors.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation
import IndiceNetworkClient

public class AuthorizationHeaderInterceptor: NetworkClient.Interceptor {
    
    private let tokenAccessor: TokenStorageAccessor
    
    public init(tokenAccessor: TokenStorageAccessor) {
        self.tokenAccessor = tokenAccessor
    }
    
    
    public func process(_ request: URLRequest, completion: (URLRequest) async throws -> NetworkClient.Result) async throws -> NetworkClient.Result {
        if let authorization = tokenAccessor.authorization {
            return try await completion(request.adding(header: .authorisation(auth: authorization)))
        }
        
        return try await completion(request)
    }
    
}




public class AuthorizingInterceptor: NetworkClient.Interceptor {
    
     private let authServiceProvider: () -> IdentityClient.UserLogin?
    
    public init(authServiceProvider: @escaping () -> IdentityClient.UserLogin?) {
        self.authServiceProvider = authServiceProvider
    }
    
    public func process(_ request: URLRequest, completion: (URLRequest) async throws -> NetworkClient.Result) async throws -> NetworkClient.Result {
        do {
            return try await completion(request)
        } catch {
            guard (error as? APIError)?.statusCode == 401 else {
                throw error
            }
            
            guard let authService = authServiceProvider() else {
                throw IdentityClient.Errors.ServiceUnavailable
            }
            
            try await authService.refreshTokens()
            return try await completion(request)
        }
    }
    
}
