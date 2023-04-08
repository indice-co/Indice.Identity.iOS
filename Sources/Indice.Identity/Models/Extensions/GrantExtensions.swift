//
//  File.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation

internal extension OAuth2Grant where Self == DeviceAuthenticationGrant {
    
    static func biometric(challenge: String,
                          codeSignature: String,
                          codeVerifier: String,
                          publicPem: String,
                          deviceIds ids: ThisDeviceIds,
                          client: Client) throws -> DeviceAuthenticationGrant {
        guard let regId = ids.registration else {
            throw IdentityClient.Errors.TrustDevice
        }
        
        return .biometrict(challenge: challenge,
                           codeSignature: codeSignature,
                           codeVerifier: codeVerifier,
                           deviceId: ids.device,
                           registrationId: regId,
                           publicKey: publicPem,
                           client: client)
    }
 
    static func pin(pin: String,
                    deviceIds ids: ThisDeviceIds,
                    client: Client) throws -> DeviceAuthenticationGrant {
        guard let regId = ids.registration else {
            throw IdentityClient.Errors.TrustDevice
        }
        
        return .pin(pin: pin,
                    deviceId: ids.device,
                    registrationId: regId,
                    client: client)
    }

    
}
