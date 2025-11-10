//
//  UsernameState.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation

public enum UsernameState: Decodable, Sendable {
    case available
    case unavailable
}
