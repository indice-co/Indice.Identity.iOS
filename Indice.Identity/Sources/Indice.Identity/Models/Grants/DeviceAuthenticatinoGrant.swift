//
//  DeviceAuthorizationGrant.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation


/** Grant used for devices authorization grant i.e. "Biometric" and "FourPin" login flows. */
public struct DeviceAuthenticationGrant: OAuth2Grant {
    public static let grantType: String = "device_authentication"
    
    let mode: String?
    let pin: String?
    let code: String?
    let code_signature: String?
    let code_verifier: String?
    let device_id: String?
    let registration_id: String?
    let public_key: String?
    let client_id: String?
    let scope: String?
    
    public var params: Params {
        ["grant_type"      : Self.grantType,
         "mode"            : mode,
         "pin"             : pin,
         "code"            : code,
         "code_signature"  : code_signature,
         "code_verifier"   : code_verifier,
         "device_id"       : device_id,
         "registration_id" : registration_id,
         "public_key"      : public_key,
         "client_id"       : client_id,
         "scope"           : scope]
            .compactMapValues { $0 }
    }
    
    public static func biometrict(challenge: String,
                                  codeSignature: String,
                                  codeVerifier: String,
                                  deviceId: String,
                                  registrationId: String,
                                  publicKey: String,
                                  client: Client) -> Self {
        DeviceAuthenticationGrant(mode            : "fingerprint",
                                 pin             : nil,
                                 code            : challenge,
                                 code_signature  : codeSignature,
                                 code_verifier   : codeVerifier,
                                 device_id       : deviceId,
                                 registration_id : registrationId,
                                 public_key      : publicKey,
                                 client_id       : client.id,
                                 scope           : client.scope)
    }
    
    public static func pin(pin: String,
                           deviceId: String,
                           registrationId: String,
                           client: Client) -> Self {
        DeviceAuthenticationGrant(mode            : "fingerprint",
                                 pin             : pin,
                                 code            : nil,
                                 code_signature  : nil,
                                 code_verifier   : nil,
                                 device_id       : deviceId,
                                 registration_id : registrationId,
                                 public_key      : nil,
                                 client_id       : client.id,
                                 scope           : client.scope)
    }
}



public extension OAuth2Grant where Self == DeviceAuthenticationGrant {
    static func pin(pin: String,
                    deviceId: String,
                    registrationId: String,
                    client: Client) -> DeviceAuthenticationGrant {
        DeviceAuthenticationGrant.pin(pin: pin,
                                      deviceId: deviceId,
                                      registrationId: registrationId,
                                      client: client)
    }
    
    static func biometrict(challenge: String,
                           codeSignature: String,
                           codeVerifier: String,
                           deviceId: String,
                           registrationId: String,
                           publicKey: String,
                           client: Client) -> DeviceAuthenticationGrant {
        DeviceAuthenticationGrant.biometrict(challenge: challenge,
                                            codeSignature: codeSignature,
                                            codeVerifier: codeVerifier,
                                            deviceId: deviceId,
                                            registrationId: registrationId,
                                            publicKey: publicKey,
                                            client: client)
    }
    
    
}
