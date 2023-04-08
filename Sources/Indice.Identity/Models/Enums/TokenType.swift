//
//  File.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation

public enum TokenType {
    case accessToken  (value: String)
    case refreshToken (value: String)
    
    public var value: String {
        switch self {
        case .accessToken  (let value): return value
        case .refreshToken (let value): return value
        }
    }
    
    public var typeHint: String {
        switch self {
        case .accessToken  : return "access_token"
        case .refreshToken : return "refresh_token"
        }
    }
}


internal extension TokenType {
    static func accessToken(value: String?) -> TokenType? {
        value != nil ? .accessToken(value: value!) : nil
    }
    
    static func refreshToken(value: String?) -> TokenType? {
        value != nil ? .refreshToken(value: value!) : nil
    }
}
