//
//  MyAccountService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation
import NetworkUtilities

public class MyAccountRepositoryImpl : MyAccountRepository {
    
    private let configuration: IdentityConfig
    private let requestProcessor: RequestProcessor
    private let errorParser: ErrorParser
    
    public init(configuration: IdentityConfig, requestProcessor: RequestProcessor, errorParser: ErrorParser) {
        self.configuration = configuration
        self.requestProcessor = requestProcessor
        self.errorParser = errorParser
    }
    
    public func register(request registerRequest: RegisterUserRequest) async throws {
        let request = URLRequest.builder()
            .post(path: configuration.baseUrl + "/api/account/register")
            .bodyJson(of: registerRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    public func verify(password passwordRequest: ValidatePasswordRequest) async throws -> CredentialsValidationInfo {
        let request = URLRequest.builder()
            .post(path: configuration.baseUrl + "/api/account/validate-password")
            .bodyJson(of: passwordRequest)
            .build()
        
        return try await requestProcessor.process(request: request)
    }
    
    public func verify(username usernameRequest: ValidateUsernameRequest) async throws -> UsernameStateInfo {
        let request = URLRequest.builder()
            .post(path: configuration.baseUrl + "/api/account/username-exists")
            .bodyJson(of: usernameRequest)
            .build()
        
        let result: UsernameStateInfo = try await {
            do {
                try await requestProcessor.process(request: request)
                return UsernameStateInfo(result: .unavailable)
            } catch {
                guard let code = errorParser.map(error)?.statusCode else {
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
    
    public func forgot(password forgotPasswordRequest: ForgotPasswordRequest) async throws {
        let request = URLRequest.builder()
            .post(path: configuration.baseUrl + "/api/account/forgot-password")
            .bodyJson(of: forgotPasswordRequest)
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    public func forgot(passwordConfirmation confirmationRequest: ForgotPasswordConfirmation) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/account/forgot-password/confirmation")
            .bodyJson(of: confirmationRequest)
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    
    public func update(password: UpdatePasswordRequest) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/account/password")
            .bodyJson(of: password)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    public func update(email emailRequest: UpdateEmailRequest) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/account/email")
            .bodyJson(of: emailRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    public func update(phone phoneRequest: UpdatePhoneRequest) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/account/phone-number")
            .bodyJson(of: phoneRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    public func verifyEmail(with otpRequest: OtpTokenRequest) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/account/email/confirmation")
            .bodyJson(of: otpRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    public func verifyPhone(with otpRequest: OtpTokenRequest) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/account/phone-number/confirmation")
            .bodyJson(of: otpRequest)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
}
