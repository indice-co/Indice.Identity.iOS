//
//  PasswordExpirationPolicy.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation

public enum PasswordExpirationPolicy: String, Codable, CaseIterable {
    case nextLogin = "NextLogin"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semesterly = "Semesterly"
    case annually = "Annually"
    case biannually = "Biannually"
    case never = "Never"
}

