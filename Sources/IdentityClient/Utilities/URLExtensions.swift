//
//  URLExtensions.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public extension URL {
    
    @available(iOS,   deprecated: 16.0, message: "Use the built-in API instead 'append(queryItems: [URLQueryItem])'")
    @available(macOS, deprecated: 13.0, message: "Use the built-in API instead 'append(queryItems: [URLQueryItem])'")
    mutating func appendQueryItems(_ items: [URLQueryItem]) throws {
        #if os(macOS)
        if #available(macOS 13, *) {
            return self.append(queryItems: items)
        }
        #elseif os(iOS)
        if #available(iOS 16, *) {
            return self.append(queryItems: items)
        }
        #endif
        
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
    
    func appendingQueryItems(_ items: [URLQueryItem]) throws -> URL {
        var url = self
        try url.appendQueryItems(items)
        return url
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
