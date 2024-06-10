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
    
    public enum Info {
        case biometric
        case devicePin(value: String)
    }
    
    public enum Mode {
        case biometric
        case devicePin
        
        internal var value: String {
            switch self {
            case .biometric: "fingerprint"
            case .devicePin: "pin"
            }
        }
    }
    
    let mode: Mode
    let pin: String?
    let code: String?
    let code_signature: String?
    let code_verifier: String?
    let public_key: String?
    
    public var params: Params {
        ["grant_type"      : Self.grantType,
         "mode"            : mode.value,
         "pin"             : pin,
         "code"            : code,
         "code_signature"  : code_signature,
         "code_verifier"   : code_verifier,
         "public_key"      : public_key]
            .compactMapValues { $0 }
    }
}



public extension OAuth2Grant where Self == DeviceAuthenticationGrant {
    static func biometrict(challenge: String,
                           codeSignature: String,
                           codeVerifier: String,
                           publicKey: String) -> Self {
        DeviceAuthenticationGrant(mode            : .biometric,
                                  pin             : nil,
                                  code            : challenge,
                                  code_signature  : codeSignature,
                                  code_verifier   : codeVerifier,
                                  public_key      : publicKey)
    }
    
    static func pin(value: String) -> Self {
        DeviceAuthenticationGrant(mode            : .devicePin,
                                  pin             : value,
                                  code            : nil,
                                  code_signature  : nil,
                                  code_verifier   : nil,
                                  public_key      : nil)
    }
}
