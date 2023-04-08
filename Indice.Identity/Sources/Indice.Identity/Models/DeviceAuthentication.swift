//
//  TrustDevice.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public final class DeviceAuthentication {
    
    public typealias Platform = DevicePlatform
    public typealias Mode = TrustDeviceMode

    public struct ChallengeResponse : Decodable {
        public let challenge: String
    }
    
    public struct RegistrationResult: Decodable {
        // public let deviceId: String
        public let registrationId: String
    }
    
    public struct AuthorizationRequest : Codable {
        public var code_challenge: String
        public var device_id: String
        public var mode: TrustDeviceMode
        public var client_id: String
        public var scope: String
        public var registration_id: String?
        public var channel: TotpDeliveryChannel?
        
        public init(code_challenge: String,
                    device_id: String,
                    mode: TrustDeviceMode,
                    client_id: String,
                    scope: String,
                    registration_id: String?,
                    channel: TotpDeliveryChannel? = nil) {
            self.code_challenge = code_challenge
            self.device_id = device_id
            self.mode = mode
            self.client_id = client_id
            self.scope = scope
            self.registration_id = registration_id
            self.channel = channel
        }
    }
    
    public struct RegistrationRequest : Codable {
        
        public let code: String?
        public let code_verifier: String?
        public let code_signature: String?
        public let mode: Mode?
        public let device_id: String?
        public let device_name: String?
        public let device_platform: Platform?
        public let otp: String?
        public let public_key: String?
        public let pin: String?
        
        public init(code: String?,
                    code_verifier: String?,
                    code_signature: String?,
                    mode: Mode?,
                    device_id: String?,
                    device_name: String?,
                    device_platform: Platform?,
                    otp: String?,
                    public_key: String?,
                    pin: String?) {
            self.code = code
            self.code_verifier = code_verifier
            self.code_signature = code_signature
            self.mode = mode
            self.device_id = device_id
            self.device_name = device_name
            self.device_platform = device_platform
            self.otp = otp
            self.public_key = public_key
            self.pin = pin
        }
    }
}
