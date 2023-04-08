//
//  APIErrorExtensions.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import IndiceNetworkClient

extension APIError: Equatable {
    
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
        && lhs.statusCode == rhs.statusCode
        && lhs.raw == rhs.raw
    }
    
}
