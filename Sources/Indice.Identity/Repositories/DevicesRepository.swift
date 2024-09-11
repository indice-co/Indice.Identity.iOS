//
//  DevicesService.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation
import NetworkUtilities

public class DevicesRepositoryImpl: DevicesRepository {

    let configuration : IdentityConfig
    let requestProcessor : RequestProcessor
    
    public init(configuration: IdentityConfig, requestProcessor: RequestProcessor) {
        self.configuration = configuration
        self.requestProcessor = requestProcessor
    }
    
}


// MARK: - Device authentication

public extension DevicesRepositoryImpl {
    
    func authorize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse {
        let request = URLRequest.builder()
            .post(path: configuration.deviceRegistration.authorizeEndpoint)
            .bodyFormUtf8(params: authRequest.asDict!)
            .add(header: .accept(type: .json))
            .build()
        
        return try await requestProcessor.process(request: request)
    }
    
    
    func initialize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse {
        let request = URLRequest.builder()
            .post(path: configuration.deviceRegistration.initializeEndpoint)
            .bodyFormUtf8(params: authRequest.asDict!)
            .add(header: .accept(type: .json))
            .build()
        
        return try await requestProcessor.process(request: request)
    }
    
    
    func complete(registrationRequest: DeviceAuthentication.RegistrationRequest) async throws -> DeviceAuthentication.RegistrationResult {
        let request = URLRequest.builder()
            .post(path: configuration.deviceRegistration.completionEndpoint)
            .bodyFormUtf8(params: registrationRequest.asDict!)
            .add(header: .accept(type: .json))
            .build()
        
        return try await requestProcessor.process(request: request)
    }
}


// MARK: - Device management

public extension DevicesRepositoryImpl {
    
    func devices() async throws -> ResultSet<DeviceInfo> {
        let request = URLRequest.builder()
            .get(path: configuration.baseUrl + "/api/my/devices")
            .add(header: .accept(type: .json))
            .build()
        
        return try await requestProcessor.process(request: request)
    }
    
    func device(byId deviceId: String) async throws -> DeviceInfo {
        let request = URLRequest.builder()
            .get(path: configuration.baseUrl + "/api/my/devices/\(deviceId)")
            .add(header: .accept(type: .json))
            .build()
        
        return try await requestProcessor.process(request: request)
    }
    
    func create(device data: CreateDeviceRequest) async throws {
        let request = URLRequest.builder()
            .post(path: configuration.baseUrl + "/api/my/devices")
            .bodyJson(of: data)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    func update(deviceId: String, with data: UpdateDeviceRequest) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/devices/\(deviceId)")
            .bodyJson(of: data)
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    func delete(deviceId: String) async throws {
        let request = URLRequest.builder()
            .delete(path: configuration.baseUrl + "/api/my/devices/\(deviceId)")
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
}


// MARK: - Trust

public extension DevicesRepositoryImpl {
    
    func trust(deviceId: String, bySwappingWith otherDeviceId: String?) async throws {
        struct SwapDeviceRequest: Codable {
            let swapDeviceId: String?
        }
        
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/devices/\(deviceId)/trust")
            .bodyJson(of: SwapDeviceRequest(swapDeviceId: otherDeviceId))
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
    func unTrust(deviceId: String) async throws {
        let request = URLRequest.builder()
            .put(path: configuration.baseUrl + "/api/my/devices/\(deviceId)/untrust")
            .noBody()
            .add(header: .accept(type: .json))
            .build()
        
        try await requestProcessor.process(request: request)
    }
    
}


