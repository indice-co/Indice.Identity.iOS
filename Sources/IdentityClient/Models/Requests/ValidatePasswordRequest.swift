//
//  ValidatePasswordRequest.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 29/3/23.
//

import Foundation

public struct ValidatePasswordRequest: Codable, Sendable
{
    /// <summary>
    /// A token representing the user id.
    /// </summary>
    public let token: String
    /// <summary>
    /// The password.
    /// </summary>
    public let password: String
    /// <summary>
    /// The username.
    /// </summary>
    public let userName: String
}
