//
//  UserInformation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation

public class UserData: ObservableObject, @unchecked Sendable {
    @Published
    public internal(set)
    var info: UserInfo? = nil
}

/// User info. Is it overkill to have a service for only refreshing `UserInfo`
public actor UserService: Sendable {

    public
    nonisolated
    let user: UserData = .init()
    
    private let userRepository: UserInfoRepository
    
    init(userRepository: UserInfoRepository) {
        self.userRepository = userRepository
    }
    
    @discardableResult
    public func refreshUserInfo() async throws -> UserInfo {
        let result = try await userRepository.userInfo()
        user.info = result
        return result
    }
}
