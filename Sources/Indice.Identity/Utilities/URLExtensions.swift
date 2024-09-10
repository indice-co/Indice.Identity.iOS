//
//  URLExtensions.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public extension URL {
    
    @available(iOS, deprecated: 16.0, message: "Use the built-in API instead 'append(queryItems: [URLQueryItem])'")
    mutating func appendQueryItems(_ items: [URLQueryItem]) throws {
        guard var urlComponents = URLComponents(string: absoluteString) else {
            throw errorOfType(.url(malformedUrl: absoluteString))
        }

        let initialsParams = urlComponents.queryItems ??  []
        urlComponents.queryItems = initialsParams + items
        
        guard let newUrl = urlComponents.url else {
            throw errorOfType(.url(malformedUrl: absoluteString))
        }
        
        self = newUrl
    }
}




internal extension URLRequest {
    
    func adding(value: String?, forHeaderName name: String) -> URLRequest {
        guard let value else { return self }
        
        var request = self
        request.addValue(value, forHTTPHeaderField: name)
        
        return request
    }
    
    func setting(value: String?, forHeaderName name: String) -> URLRequest {
        var request = self
        request.setValue(value, forHTTPHeaderField: name)
        
        return request
    }
    
}
