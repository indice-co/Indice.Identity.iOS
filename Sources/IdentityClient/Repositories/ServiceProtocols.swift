//
//  ServiceProtocols.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public protocol Repository: AnyObject, Sendable { }

public protocol AuthRepository: Repository {
    func authorize(grant: OAuth2Grant) async throws -> TokenResponse
    func revoke(token: TokenType, withBasicAuth: String) async throws
}


// MARK: -

public protocol DevicesRepository: Repository {
    
    // MARK: Auth
    func authorize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse
    func initialize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse
    func complete(registrationRequest: DeviceAuthentication.RegistrationRequest) async throws -> DeviceAuthentication.RegistrationResult

    // MARK: Management
    func devices() async throws -> ResultSet<DeviceInfo>
    func device(byId: String) async throws -> DeviceInfo
    func create(device: CreateDeviceRequest) async throws
    func update(deviceId: String, with: UpdateDeviceRequest) async throws
    func delete(deviceId: String) async throws
    
    func trust(deviceId: String, bySwappingWith: String?) async throws
    func unTrust(deviceId: String) async throws
}


// MARK: -

public protocol MyAccountRepository: Repository {
    func register(request: RegisterUserRequest) async throws
    
    func verify(password: ValidatePasswordRequest) async throws -> CredentialsValidationInfo
    func verify(username: ValidateUsernameRequest) async throws
    
    func forgot(password: ForgotPasswordRequest) async throws
    func forgot(passwordConfirmation: ForgotPasswordConfirmation) async throws
    
    func update(password: UpdatePasswordRequest) async throws
    func update(email: UpdateEmailRequest) async throws
    func update(phone: UpdatePhoneRequest) async throws
    func verifyEmail(with: OtpTokenRequest) async throws
    func verifyPhone(with: OtpTokenRequest) async throws
}


public protocol UserInfoRepository: Repository {
    func userInfo() async throws -> UserInfo
}


// MARK: -

public struct ThisDeviceIds: Sendable {
    public var device       : String
    public var registration : String?
}

public struct ThisDeviceInfo: Sendable {
    public var name      : String
    public var model     : String
    public var osVersion : String
}

public protocol ThisDeviceRepository: Repository {
    typealias Ids  = ThisDeviceIds
    typealias Info = ThisDeviceInfo
    
    var ids  : Ids  { get }
    var info : Info { get }

    /** Clears the current device & registration ids. */
    func resetIds()
    
    /** Update and store the new registration id of the device */
    @discardableResult
    func update(registrationId: String?) -> Bool
}
