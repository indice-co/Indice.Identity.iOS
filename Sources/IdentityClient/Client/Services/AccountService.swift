//
//  UserVerification.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 10/4/23.
//

import Foundation


/// Service responsible for updating the users account
public class AccountService {
    
    private let accountRepository: MyAccountRepository
    
    init(accountRepository: MyAccountRepository) {
        self.accountRepository = accountRepository
    }
    
    /// Update the user's current phone number
    public func update(phone: String, otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> () {
        try await accountRepository.update(phone: .init(phoneNumber: phone, deliveryChannel: otpChannel))
        
        return { [weak self] otpResult in
            guard let self = self else { return }
            guard let otp = otpResult.otpValue else { return }
            
            try await accountRepository.verifyPhone(with: .init(token: otp))
        }
        
    }
    
    /// Update the user's current email
    public func update(email: String, returnUrl: String?) async throws {
        try await accountRepository.update(email: .init(email: email, returnUrl: returnUrl /* Set return URL? */))
        // TODO: Complete flow here?
        // User would go to mail, and then manually return to the app to check if their mail is verified.
    }
    
    /// Confirm the user's current email
    public func confirmEmail(withToken token: String) async throws {
        try await accountRepository.verifyEmail(with: .init(token: token))
    }
    
    /// Update the user's current password
    public func update(password passwordRequest: UpdatePasswordRequest) async throws {
        try await accountRepository.update(password: passwordRequest)
    }
    
    
    /// Initiate the forgot password flow
    public func forgotPasswordInitialize(email: String, returnUrl: String) async throws {
        try await accountRepository.forgot(password: .init(email: email, returnUrl: returnUrl))
    }
    
    /// Confirm forgot password and set a new one
    public func forgotPasswordConfirmation(token: String, email: String, password: String, passwordConfirmation: String, returnUrl: String) async throws {
        try await accountRepository.forgot(passwordConfirmation: .init(email: email,
                                                                       newPassword: password,
                                                                       newPasswordConfirmation: passwordConfirmation,
                                                                       returnUrl: returnUrl,
                                                                       token: token))
    }
   
}

