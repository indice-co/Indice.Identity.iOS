//
//  Grant.swift
//  INOpenId
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//

import Foundation


public protocol OAuth2Grant {
    typealias Params = [String: Any]
    
    /** The grant flow type name */
    static var grantType: String { get }
    
    /** Any extra parameter that the grant needs - to be form-encoded.  */
    var params: Params { get }
}

public extension OAuth2Grant {
    var grantType: String { Self.grantType }
}
