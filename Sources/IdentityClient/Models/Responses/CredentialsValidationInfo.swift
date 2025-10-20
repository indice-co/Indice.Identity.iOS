//
//  CredentialsValidationInfo.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 10/4/23.
//

import Foundation

public struct CredentialsValidationInfo: Decodable {
    let passwordRules: [PasswordRuleInfo]?
}
