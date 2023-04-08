//
//  RegisterUserRequest.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 4/4/23.
//

import Foundation

public struct RegisterUserRequest: Codable {
    public let firstName: String?
    public let lastName: String?
    public let userName: String
    public let password: String
    public let passwordConfirmation: String
    public let email: String
    public let phoneNumber: String?
    public let hasReadPrivacyPolicy: Bool
    public let hasAcceptedTerms: Bool
}
