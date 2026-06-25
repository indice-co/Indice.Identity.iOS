//
//  UserInformation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation
import Combine

/// User info. Is it overkill to have a service for only refreshing `UserInfo`
final public actor UserService: Sendable {

    @MainActor
    private let userInternal = CurrentValueSubject<UserInfo?, Never>(nil)
    
    @MainActor
    public var user: AnyPublisher<UserInfo?, Never> {
        userInternal.eraseToAnyPublisher()
    }
    
    private let userRepository: UserInfoRepository
    private var infoState: UserInfo? = nil
    
    init(userRepository: UserInfoRepository) {
        self.userRepository = userRepository
    }
    
    public var info: UserInfo? {
        infoState
    }
    
    @discardableResult
    public func refreshUserInfo() async throws -> UserInfo {
        let result = try await userRepository.userInfo()
        infoState = result
        
        await MainActor.run {
            userInternal.send(result)
        }
        
        return result
    }
}
