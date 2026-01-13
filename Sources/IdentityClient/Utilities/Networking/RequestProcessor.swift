//
//  RequestProcessor.swift
//
//
//  Created by Nikolas Konstantakopoulos on 5/11/23.
//

import Foundation


public protocol RequestProcessor: AnyObject, Sendable {
    
    func process(request: URLRequest) async throws
    
    func process<T: Decodable>(request: URLRequest) async throws -> T where T: Sendable
}




final internal class RequestProcessorWrapper: RequestProcessor, Sendable {
    
    let processor: RequestProcessor
    let tokenAccessor: TokenStorageAccessor
    
    init(processor: RequestProcessor, tokenAccessor: TokenStorageAccessor) {
        self.processor = processor
        self.tokenAccessor = tokenAccessor
    }
    
    func process(request: URLRequest) async throws {
        guard !request.hasAuthorizationHeaderSet else {
            try await processor.process(request: request)
            return
        }
        
        try await processor.process(request: request
            .setting(value: tokenAccessor.authorization,
                     forHeaderName: "Authorization"))
    }
    
    func process<T>(request: URLRequest) async throws -> T where T : Decodable, T: Sendable {
        guard !request.hasAuthorizationHeaderSet else {
            return try await processor.process(request: request)
        }
        
        return try await processor.process(request: request
            .setting(value: tokenAccessor.authorization,
                     forHeaderName: "Authorization"))
    }
}


private extension URLRequest {
    
    var hasAuthorizationHeaderSet: Bool {
        allHTTPHeaderFields?["Authorization"] != nil
    }
}
