//
//  Client.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public protocol Client {
    var id     : String  { get }
    var scope  : String  { get }
    var secret : String? { get }
}


public extension Client {
    var basicAuth: String { get {
       "Basic " +
            (id + ":" + (secret ?? ""))
                .data(using: .utf8)!
                .base64EncodedString()
    } }
}
