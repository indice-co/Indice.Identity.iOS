//
//  UpdateEmailRequest.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation

public struct UpdateEmailRequest: Codable {
    public let email: String
    public let returnUrl: String?
    
    public init(email: String, returnUrl: String?) {
        self.email = email
        self.returnUrl = returnUrl
    }
}
