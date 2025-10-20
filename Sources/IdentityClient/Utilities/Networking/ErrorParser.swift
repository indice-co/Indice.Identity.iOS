//
//  ErrorParser.swift
//
//
//  Created by Nikolas Konstantakopoulos on 29/7/24.
//

import Foundation

public struct ErrorParser {
    let map: (Swift.Error) -> IdentityClient.Error.APIError?
    
    public init(map: @escaping (Swift.Error) -> IdentityClient.Error.APIError?) {
        self.map = map
    }
}
