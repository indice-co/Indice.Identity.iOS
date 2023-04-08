//
//  UserInformation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation

public class IndiceClientUserInformation: ObservableObject {
    @Published
    public internal(set)
    var info: UserInfo? = nil
}

public protocol IndiceClientUserInformationService {
    
    var user: IndiceClientUserInformation { get }
    
    func refreshUserInfo() async throws
}


extension IdentityClient: IndiceClientUserInformationService {
    
    public typealias UserService     = IndiceClientUserInformationService
    public typealias UserInformation = IndiceClientUserInformation

    public var userService: UserService { self }

    public func refreshUserInfo() async throws {
        user.info = try await userRepository.userInfo()
    }
    
}
