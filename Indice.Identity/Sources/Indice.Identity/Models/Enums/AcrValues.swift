//
//  AcrValues.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public enum AcrValues {
    case apple, google, microsoft
    case custom(value: String)
    
    public var value: String {
        switch self {
        case .apple: return "idp:Apple"
        case .google: return "idp:Google"
        case .microsoft: return "idp:Microsoft"
        case .custom(let value): return value
        }
    }
    
}
