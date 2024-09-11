//
//  Error.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 23/7/24.
//

import Foundation


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
    
    public struct APIError {
        let statusCode: Int
        let details: ExtendedProblemDetails?
        
        public init(statusCode: Int, details: ExtendedProblemDetails?) {
            self.statusCode = statusCode
            self.details = details
        }
    }
}

internal func errorOfType(_ provider: @autoclosure () -> IdentityClient.Error) -> IdentityClient.Error {
    provider()
}
