//
//  MyAccountService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation
import IndiceNetworkClient


public class MyAccountRepositoryImpl : MyAccountRepository {
    
    private let authorization: Authorization
    private let networkClient: NetworkClient
    
    public init(authorization: Authorization, networkClient: NetworkClient) {
        self.authorization = authorization
        self.networkClient = networkClient
    }
    
    
    public func register(request registerRequest: RegisterUserRequest) async throws {
        let request = URLRequest.builder()
            .post(path: authorization.baseUrl + "/api/account/register")
            .bodyJson(of: registerRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
    public func verify(password passwordRequest: ValidatePasswordRequest) async throws -> [PasswordRuleInfo] {
        let request = URLRequest.builder()
            .post(path: authorization.baseUrl + "/api/account/validate-password")
            .bodyJson(of: passwordRequest)
            .build()
        
        return try await networkClient.fetch(request: request)
    }
    
    public func verify(username usernameRequest: ValidateUsernameRequest) async throws -> UsernameStateInfo {
        let request = URLRequest.builder()
            .post(path: authorization.baseUrl + "/api/account/username-exists")
            .bodyJson(of: usernameRequest)
            .build()
        
        let result: UsernameStateInfo = try await {
            do {
                try await networkClient.fetch(request: request)
                return UsernameStateInfo(result: .available)
            } catch {
                guard let code = (error as? APIError)?.statusCode else {
                    throw error
                }
                    
                switch code {
                case 404: return UsernameStateInfo(result: .available)
                case 302: return UsernameStateInfo(result: .unavailable)
                default: throw error
                }
            }
        }()
        
        return result
    }
    
    public func update(email emailRequest: UpdateEmailRequest) async throws {
        let request = URLRequest.builder()
            .put(path: authorization.baseUrl + "/api/my/account/email")
            .bodyJson(of: emailRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
    public func update(phone phoneRequest: UpdatePhoneRequest) async throws {
        let request = URLRequest.builder()
            .put(path: authorization.baseUrl + "/api/my/account/phone-number")
            .bodyJson(of: phoneRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
    public func verifyEmail(with otpRequest: OtpTokenRequest) async throws {
        let request = URLRequest.builder()
            .put(path: authorization.baseUrl + "/api/my/account/email/confirmation")
            .bodyJson(of: otpRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
    public func verifyPhone(with otpRequest: OtpTokenRequest) async throws {
        let request = URLRequest.builder()
            .put(path: authorization.baseUrl + "/api/my/account/phone-number/confirmation")
            .bodyJson(of: otpRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
}
