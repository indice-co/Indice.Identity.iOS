//
//  IdentityClientUserRegistration.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation
import IndiceNetworkClient

/** Registers a new user and aids to the username/password verification prior. */
public protocol UserRegistrationService {
    func register(request: RegisterUserRequest) async throws
    
    func verify(username: String) async throws -> UsernameStateInfo
    func verify(password: String) async throws -> [PasswordRuleInfo]
}

internal class UserRegistrationServiceImpl: UserRegistrationService {

    private let accountRepository: MyAccountRepository
    
    init(accountRepository: MyAccountRepository) {
        self.accountRepository = accountRepository
    }
    
    public func register(request: RegisterUserRequest) async throws {
        try await accountRepository.register(request: request)
    }

    public func verify(username: String) async throws -> UsernameStateInfo {
        try await accountRepository.verify(username: .init(userName: username))
    }
    
    public func verify(password: String) async throws -> [PasswordRuleInfo] {
        try await accountRepository.verify(password: .init(token: "",
                                                           password: password,
                                                           userName: "")).passwordRules ?? []
    }

}
