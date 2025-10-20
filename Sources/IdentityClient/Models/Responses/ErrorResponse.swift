//
//  ErrorResponse.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//


import Foundation

/** A basic error model that is returned on an auth request. */
public struct ErrorResponse: Codable {
    public let error: String
    public let description: String?
}

public extension ErrorResponse {
    
    enum CodingKeys: CodingKey {
        case error
        case error_description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decode(String.self, forKey: .error)
        self.description = try container.decodeIfPresent(String.self, forKey: .error_description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.error, forKey: .error)
        try container.encodeIfPresent(self.description, forKey: .error_description)
    }
    
}
