//
//  UserVerification.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 10/4/23.
//

import Foundation


/** Service responsible for updating the users account */
public protocol AccountService: AnyObject {
    /** Update  the user's current phone number */
    @available(*, deprecated, renamed: "update(phone:otpChannel:)", message: "The async otpProvider is tricky too handle. Use the update(phone: String, otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> () instead, to get an otp completion handler.")
    func update(phone: String, otpChannel: TotpDeliveryChannel?, otpProvider: CallbackType.OtpProvider) async throws
    
    /** Update  the user's current phone number */
    func update(phone: String, otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> ()
    
    /** Update  the user's current email */
    func update(email: String, returnUrl: String?) async throws
    
    /** Update the user's current password */
    func update(password: UpdatePasswordRequest) async throws
    
    
    /** Initiate the forgot password flow */
    func forgotPasswordInitialize(email: String, returnUrl: String) async throws
    
    /** Confirm forgot password and set a new one */
    func forgotPasswordConfirmation(token: String, email: String, password: String, passwordConfirmation: String, returnUrl: String) async throws
}


internal class AccountServiceImpl : AccountService {
    
    private let accountRepository: MyAccountRepository
    private let userService: UserService
    
    init(accountRepository: MyAccountRepository, userService: UserService) {
        self.accountRepository = accountRepository
        self.userService = userService
    }
    
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
    
    
    public func update(email: String, returnUrl: String?) async throws {
        try await accountRepository.update(email: .init(email: email, returnUrl: returnUrl /* Set return URL? */))
        // TODO: Complete flow here?
        // User would go to mail, and then manually return to the app to check if their mail is verified.
    }
    
    public func update(password passwordRequest: UpdatePasswordRequest) async throws {
        try await accountRepository.update(password: passwordRequest)
    }
    
    
    
    public func forgotPasswordInitialize(email: String, returnUrl: String) async throws {
        try await accountRepository.forgot(password: .init(email: email, returnUrl: returnUrl))
    }
    
    public func forgotPasswordConfirmation(token: String, email: String, password: String, passwordConfirmation: String, returnUrl: String) async throws {
        try await accountRepository.forgot(passwordConfirmation: .init(email: email,
                                                                       newPassword: password,
                                                                       newPasswordConfirmation: passwordConfirmation,
                                                                       returnUrl: returnUrl,
                                                                       token: token))
    }
   
}

