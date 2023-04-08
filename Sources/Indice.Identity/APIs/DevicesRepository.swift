//
//  DevicesService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation
import IndiceNetworkClient

public class DevicesRepositoryImpl: DevicesRepository {

    let authorization : Authorization
    let networkClient : NetworkClient
    
    public init(authorization: Authorization, networkClient: NetworkClient) {
        self.authorization = authorization
        self.networkClient = networkClient
    }
    
}


// MARK: - Device authentication

public extension DevicesRepositoryImpl {
    
    func authorize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse {
        let request = URLRequest.builder()
            .post(path: authorization.deviceRegistration.authorizeEndpoint)
            .bodyFormUtf8(params: authRequest.asDict!)
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }
    
    
    func initialize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse {
        let request = URLRequest.builder()
            .post(path: authorization.deviceRegistration.initializeEndpoint)
            .bodyFormUtf8(params: authRequest.asDict!)
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }
    
    
    func complete(registrationRequest: DeviceAuthentication.RegistrationRequest) async throws -> DeviceAuthentication.RegistrationResult {
        let request = URLRequest.builder()
            .post(path: authorization.deviceRegistration.completionEndpoint)
            .bodyFormUtf8(params: registrationRequest.asDict!)
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }
}


// MARK: - Device management

public extension DevicesRepositoryImpl {
    
    func devices() async throws -> ResultSet<DeviceInfo> {
        let request = URLRequest.builder()
            .get(path: authorization.baseUrl + "/api/my/devices")
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }
    
    func device(byId deviceId: String) async throws -> DeviceInfo {
        let request = URLRequest.builder()
            .get(path: authorization.baseUrl + "/api/my/devices/\(deviceId)")
            .add(header: .accept(type: .json))
            .build()
        
        return try await networkClient.fetch(request: request)
    }
    
    func create(device data: CreateDeviceRequest) async throws {
        let request = URLRequest.builder()
            .post(path: authorization.baseUrl + "/api/my/devices")
            .bodyJson(of: data)
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
    func update(deviceId: String, with data: UpdateDeviceRequest) async throws {
        let request = URLRequest.builder()
            .put(path: authorization.baseUrl + "/api/my/devices/\(deviceId)")
            .bodyJson(of: data)
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
    func delete(deviceId: String) async throws {
        let request = URLRequest.builder()
            .delete(path: authorization.baseUrl + "/api/my/devices/\(deviceId)")
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
}


// MARK: - Trust

public extension DevicesRepositoryImpl {
    
    func trust(deviceId: String, bySwappingWith otherDeviceId: String?) async throws {
        struct SwapDeviceRequest: Codable {
            let swapDeviceId: String?
        }
        
        let request = URLRequest.builder()
            .put(path: authorization.baseUrl + "/api/my/devices/\(deviceId)/trust")
            .bodyJson(of: SwapDeviceRequest(swapDeviceId: otherDeviceId))
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
    func unTrust(deviceId: String) async throws {
        let request = URLRequest.builder()
            .put(path: authorization.baseUrl + "/api/my/devices/\(deviceId)/untrust")
            .noBody()
            .add(header: .accept(type: .json))
            .build()
        
        try await networkClient.fetch(request: request)
    }
    
}


