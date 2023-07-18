//
//  UserVerification.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 10/4/23.
//

import Foundation



public protocol IdentityClientUserVerification {
    /** Update  the user's current phone number */
    func update(phone: String, otpChannel: TotpDeliveryChannel?, otpProvider: CallbackType.OtpProvider) async throws
    
    func update(phone: String, otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> ()
    
    /** Update  the user's current email */
    func update(email: String, otpChannel: TotpDeliveryChannel?) async throws
    
    /** Update the user's current password */
    func update(password: UpdatePasswordRequest) async throws
}

extension IdentityClient : IdentityClientUserVerification {
    
    public typealias UserVerification = IdentityClientUserVerification
    
    public func update(phone: String, otpChannel: TotpDeliveryChannel? = nil, otpProvider: CallbackType.OtpProvider) async throws {
        
        try await accountRepository.update(phone: .init(phoneNumber: phone, deliveryChannel: otpChannel))
        
        let otpResult = await otpProvider(true)
        
        guard case .submit(let value) = otpResult else {
            // TODO: Should this throw something?
            return
        }
        
        try await accountRepository.verifyPhone(with: .init(token: value))
        try await userService.refreshUserInfo()
    }
    
    
    public func update(phone: String, otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> () {
        try await accountRepository.update(phone: .init(phoneNumber: phone, deliveryChannel: otpChannel))
        
        return { [weak self] otpResult in
            guard let self = self else { return }
            guard let otp = otpResult.otpValue else { return }
            
            try await accountRepository.verifyPhone(with: .init(token: otp))
        }
        
    }
    
    
    public func update(email: String, otpChannel: TotpDeliveryChannel? = nil) async throws {
        try await accountRepository.update(email: .init(email: email, returnUrl: nil /* Set return URL? */))
        // TODO: Complete flow here?
        // User would go to mail, and then manually return to the app to check if their mail is verified.
    }
    
    public func update(password passwordRequest: UpdatePasswordRequest) async throws {
        try await accountRepository.update(password: passwordRequest)
    }
        
}

