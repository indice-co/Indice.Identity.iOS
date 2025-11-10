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
    
    private let processor: RequestProcessor
    private let tokenAccessor: TokenStorageAccessor
    
    init(processor: RequestProcessor, tokenAccessor: TokenStorageAccessor) {
        self.processor = processor
        self.tokenAccessor = tokenAccessor
    }
    
    func process(request: URLRequest) async throws {
        try await processor.process(request: request
            .setting(value: tokenAccessor.authorization,
                     forHeaderName: "Authorization"))
    }
    
    func process<T>(request: URLRequest) async throws -> T where T : Decodable, T: Sendable {
        try await processor.process(request: request
            .setting(value: tokenAccessor.authorization,
                     forHeaderName: "Authorization"))
    }
}





