//
//  ForgotPasswordConfirmation.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 12/6/23.
//

import Foundation


public struct ForgotPasswordConfirmation: Codable, Sendable {
    
    public let email: String
    public let newPassword: String
    public let newPasswordConfirmation: String
    public let returnUrl: String
    
    public let token: String
    
    public init(email: String, newPassword: String, newPasswordConfirmation: String, returnUrl: String, token: String) {
        self.email = email
        self.newPassword = newPassword
        self.newPasswordConfirmation = newPasswordConfirmation
        self.returnUrl = returnUrl
        self.token = token
    }
    
}
