//
//  IdentityClientUserRegistration.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation
import IndiceNetworkClient

public protocol IdentityClientUserRegistration {
    func register(request: RegisterUserRequest) async throws
}

extension IdentityClient: IdentityClientUserRegistration {
    public typealias UserRegistration = IdentityClientUserRegistration
    
    public var userRegistrationService: UserRegistration { self }
    
    public func register(request: RegisterUserRequest) async throws {
        try await accountRepository.register(request: request)
    }

}
