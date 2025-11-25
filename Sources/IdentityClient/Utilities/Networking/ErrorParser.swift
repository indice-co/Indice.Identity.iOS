//
//  ErrorParser.swift
//
//
//  Created by Nikolas Konstantakopoulos on 29/7/24.
//

import Foundation

public struct ErrorParser: Sendable {
    let map: @Sendable (Swift.Error) -> IdentityClient.Error.APIError?
    
    public init(map: @Sendable @escaping (Swift.Error) -> IdentityClient.Error.APIError?) {
        self.map = map
    }
}
