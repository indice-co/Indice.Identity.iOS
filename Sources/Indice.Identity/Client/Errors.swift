//
//  Error.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 23/7/24.
//

import Foundation
import IndiceNetworkClient

public enum IdentityClientErrors: Error, Equatable {
    
    case url(malformedUrl: String?)
    case authorization(error: AuthorizationError)
    case biometric(error: BiometricError)
    case domain(unavailable: DomainError)
    case trustedDevice(error: DeviceError)
    
    
    public enum AuthorizationError: Equatable {
        case refreshTokenMissing
        case registrationIdMissing
    }
    
    public enum BiometricError: Equatable {
        case userCanceled
        case dataMissing
    }
    
    public enum DomainError: Equatable {
        case authorization
        case account
        case devices
        case userInformation
        case userRegistration
    }

    public enum DeviceError: Equatable {
        case limitReached
    }
}

extension Swift.Error {
    var statusCode: Int? {
        (self as? NetworkClient.Error)?.statusCode
    }
}


internal func errorOfType(_ provider: @autoclosure () -> IdentityClient.Error) -> IdentityClient.Error {
    provider()
}
