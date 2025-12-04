//
//  Error.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 23/7/24.
//

import Foundation


public enum IdentityClientErrors: Error, Equatable, Sendable {
    
    case url(malformedUrl: String?)
    case authorization(error: AuthorizationError)
    case biometric(error: BiometricError)
    case domain(unavailable: DomainError)
    case trustedDevice(error: DeviceError)
    
    
    public enum AuthorizationError: Equatable, Sendable {
        case refreshTokenMissing
        case registrationIdMissing
    }
    
    public enum BiometricError: Equatable, Sendable {
        case userCanceled
        case dataMissing
    }
    
    public enum DomainError: Equatable, Sendable {
        case authorization
        case account
        case devices
        case userInformation
        case userRegistration
    }

    public enum DeviceError: Equatable, Sendable {
        case limitReached
    }
    
    public struct APIError: Sendable {
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
