//
//  Interceptors.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation
import IndiceNetworkClient

/** Relies on a TokenStorageAccessor to read and add the proper Authorization header to requests in the chain. */
public class AuthorizationHeaderInterceptor: NetworkClient.Interceptor {
    private let tokenAccessor: TokenStorageAccessor
    
    public init(tokenAccessor: TokenStorageAccessor) {
        self.tokenAccessor = tokenAccessor
    }
    
    public func process(_ request: URLRequest, completion: (URLRequest) async throws -> Data) async throws -> Data {
        if let authorization = tokenAccessor.authorization {
            return try await completion(request.adding(header: .authorisation(auth: authorization)))
        }
        
        return try await completion(request)
    }
    
}



/** Relies on a provided ``AuthorizationService`` to try and refresh the access token in case of a 401 http error. */
public class AuthorizingInterceptor: NetworkClient.Interceptor {
    
    private let authServiceProvider: () -> AuthorizationService?
    
    public init(authServiceProvider: @escaping () -> AuthorizationService?) {
        self.authServiceProvider = authServiceProvider
    }
    
    public func process(_ request: URLRequest, completion: (URLRequest) async throws -> Data) async throws -> Data {
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
