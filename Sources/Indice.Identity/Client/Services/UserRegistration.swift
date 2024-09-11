//
//  IdentityClientUserRegistration.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation
import NetworkUtilities

/** Registers a new user and aids to the username/password verification prior. */
public protocol UserRegistrationService {
    func register(request: RegisterUserRequest) async throws
    
    func verify(username: String) async throws -> UsernameStateInfo
    func verify(password: String) async throws -> [PasswordRuleInfo]
}

internal class UserRegistrationServiceImpl: UserRegistrationService {

    private let accountRepository: MyAccountRepository
    private let errorParser: ErrorParser
    
    init(accountRepository: MyAccountRepository, errorParser: ErrorParser) {
        self.accountRepository = accountRepository
        self.errorParser = errorParser
    }
    
    public func register(request: RegisterUserRequest) async throws {
        try await accountRepository.register(request: request)
    }

    public func verify(username: String) async throws -> UsernameStateInfo {
        let result: UsernameStateInfo = try await {
            do {
                try await accountRepository.verify(username: .init(userName: username))
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
    
    public func verify(password: String) async throws -> [PasswordRuleInfo] {
        try await accountRepository.verify(password: .init(token: "",
                                                           password: password,
                                                           userName: "")).passwordRules ?? []
    }

}
