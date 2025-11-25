//
//  UpdatePasswordRequest.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 9/6/23.
//

import Foundation

public struct UpdatePasswordRequest: Codable, Sendable {
    public let oldPassword: String
    public let newPassword: String
    public let newPasswordConfirmation: String
    
    public init(oldPassword: String, newPassword: String, newPasswordConfirmation: String) {
        self.oldPassword = oldPassword
        self.newPassword = newPassword
        self.newPasswordConfirmation = newPasswordConfirmation
    }
}
