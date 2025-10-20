//
//  ValidateUsernameRequest.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 29/3/23.
//

import Foundation

public struct ValidateUsernameRequest: Codable
{
    /// <summary>
    /// The username.
    /// </summary>
    public let userName: String
}
