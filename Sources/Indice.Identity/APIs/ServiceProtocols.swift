//
//  ServiceProtocols.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public protocol AuthRepository: AnyObject {
    func authorize(grant: OAuth2Grant) async throws -> TokenResponse
    func revoke(token: TokenType, withBasicAuth: String) async throws
}


// MARK: -

public protocol DevicesRepository: AnyObject {
    
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

public protocol MyAccountRepository: AnyObject {
    func register(request: RegisterUserRequest) async throws
    
    func verify(password: ValidatePasswordRequest) async throws -> CredentialsValidationInfo
    func verify(username: ValidateUsernameRequest) async throws -> UsernameStateInfo
    
    func update(email: UpdateEmailRequest) async throws
    func update(phone: UpdatePhoneRequest) async throws
    func verifyEmail(with: OtpTokenRequest) async throws
    func verifyPhone(with: OtpTokenRequest) async throws
}


public protocol UserInfoRepository: AnyObject {
    func userInfo() async throws -> UserInfo
}


// MARK: -

public struct ThisDeviceIds {
    var device       : String
    var registration : String?
}

public struct ThisDeviceInfo {
    var name      : String
    var model     : String
    var osVersion : String
}

public protocol ThisDeviceRepository: AnyObject {
    typealias Ids  = ThisDeviceIds
    typealias Info = ThisDeviceInfo
    
    var ids  : Ids  { get }
    var info : Info { get }

    /** Clears the current device & registration ids. */
    func resetIds()
    
    /** Update and store the new registration id of the device */
    func update(registrationId: String?)
}
