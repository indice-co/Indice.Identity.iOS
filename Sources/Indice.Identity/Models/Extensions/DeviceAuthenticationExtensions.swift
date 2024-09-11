//
//  DeviceAuthenticationExtensions.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation

// MARK: - Authorization & initialization requests (Registration init & "pre login").

internal extension DeviceAuthentication.AuthorizationRequest {
    
    // MARK: - Biometric requests
    /** Create an request body suitable for device biometric registration initialization */
    static func biometrictInit(codeChallenge: String,
                               deviceIds ids: ThisDeviceIds,
                               client: Client) -> DeviceAuthentication.AuthorizationRequest {
        try! create(codeChallenge: codeChallenge,
                     deviceIds: ids,
                     client: client,
                     requiresRegId: false,
                     mode: .biometric)
    }
    
    /** Create an request body suitable for device biometric login authorization */
    static func biometrictAuth(codeChallenge: String,
                               deviceIds ids: ThisDeviceIds,
                               client: Client) throws -> DeviceAuthentication.AuthorizationRequest {
        try create(codeChallenge: codeChallenge,
                   deviceIds: ids,
                   client: client,
                   requiresRegId: true,
                   mode: .biometric)
    }
    
    // MARK: - Device Pin requests
    /** Create an request body suitable for device pin registration initialization */
    static func pinInit(codeChallenge: String,
                        deviceIds ids: ThisDeviceIds,
                        client: Client) -> DeviceAuthentication.AuthorizationRequest {
        try! create(codeChallenge: codeChallenge,
                   deviceIds: ids,
                   client: client,
                   requiresRegId: false,
                   mode: .pin)
    }
        
        
    // MARK: - Helper init
    
    private static func create(codeChallenge: String,
                               deviceIds ids: ThisDeviceIds,
                               client: Client,
                               requiresRegId: Bool,
                               mode: TrustDeviceMode,
                               channel: TotpDeliveryChannel? = nil) throws -> DeviceAuthentication.AuthorizationRequest {
        
        return .init(code_challenge: codeChallenge,
                     device_id: ids.device,
                     mode: mode,
                     client_id: client.id,
                     scope: client.userScope.value,
                     registration_id: try {
                         if requiresRegId && ids.registration == nil {
                             throw errorOfType(.authorization(error: .registrationIdMissing))
                         }
                         return ids.registration
                     }(),
                     channel: channel)
    }
    
}


// MARK: - Completion Requests (Complete registration)

internal extension DeviceAuthentication.RegistrationRequest {
    
    static func pin(code: String,
                    codeVerifier: String,
                    codeSignature: String,
                    deviceIds: ThisDeviceIds,
                    deviceInfo: ThisDeviceInfo,
                    devicePin: String,
                    otp: String?) -> DeviceAuthentication.RegistrationRequest {
        .init(code: code,
              code_verifier: codeVerifier,
              code_signature: codeSignature,
              mode: .pin,
              device_id: deviceIds.device,
              device_name: deviceInfo.name,
              device_platform: .ios,
              otp: otp,
              public_key: nil,
              pin: devicePin)
    }

    static func biometric(code: String,
                          codeVerifier: String,
                          codeSignature: String,
                          deviceIds: ThisDeviceIds,
                          deviceInfo: ThisDeviceInfo,
                          publicPem: String,
                          otp: String?) -> DeviceAuthentication.RegistrationRequest {
        .init(code: code,
              code_verifier: codeVerifier,
              code_signature: codeSignature,
              mode: .biometric,
              device_id: deviceIds.device,
              device_name: deviceInfo.name,
              device_platform: .ios,
              otp: otp,
              public_key: publicPem,
              pin: nil)
    }
    
}
