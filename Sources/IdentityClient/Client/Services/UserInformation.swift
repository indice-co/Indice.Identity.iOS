//
//  UserInformation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation

public class UserData: ObservableObject {
    @Published
    public internal(set)
    var info: UserInfo? = nil
}

/** User info. Is it overkill to have a service for only refreshing ``UserInfo``? */
public protocol UserService: AnyObject {
    
    var user: UserData { get }
    
    func refreshUserInfo() async throws
}


internal class UserServiceImpl: UserService {

    public
    private(set)
    var user: UserData = .init()
    
    private let userRepository: UserInfoRepository
    
    init(userRepository: UserInfoRepository) {
        self.userRepository = userRepository
    }
    
    public func refreshUserInfo() async throws {
        user.info = try await userRepository.userInfo()
    }
    
}
