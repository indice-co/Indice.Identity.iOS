//
//  PasswordRuleInfo.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation

public struct PasswordRuleInfo: Decodable {
    public let code: String?
    public let description: String
    public let requirement: String
    public let isValid: Bool
}
