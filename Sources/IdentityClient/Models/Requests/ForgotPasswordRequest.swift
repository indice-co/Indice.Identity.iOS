//
//  ForgotPasswordRequest.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 12/6/23.
//

import Foundation

public struct ForgotPasswordRequest: Codable, Sendable {
    public let email: String
    public let returnUrl: String?
    
    public init(email: String, returnUrl: String?) {
        self.email = email
        self.returnUrl = returnUrl
    }
}
