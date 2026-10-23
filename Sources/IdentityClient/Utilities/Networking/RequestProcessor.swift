//
//  RequestProcessor.swift
//
//
//  Created by Nikolas Konstantakopoulos on 5/11/23.
//

import Foundation
import NetworkUtilities


public typealias RequestProcessor = NetworkUtilities::RequestProcessor


final internal class RequestProcessorWrapper: RequestProcessor, Sendable {
    
    let processor: RequestProcessor
    let tokenAccessor: TokenStorageAccessor
    
    init(processor: RequestProcessor, tokenAccessor: TokenStorageAccessor) {
        self.processor = processor
        self.tokenAccessor = tokenAccessor
    }
    
    func fetch(request: URLRequest) async throws -> Response<Void> {
        guard !request.hasAuthorizationHeaderSet else {
            return try await processor.fetch(request: request)
        }
        
        return try await processor.fetch(
            request: request.setting(
                value: tokenAccessor.authorization,
                forHeaderName: "Authorization"))
    }
    
    func fetch<T>(request: URLRequest) async throws -> Response<T> where T : Decodable, T: Sendable {
        guard !request.hasAuthorizationHeaderSet else {
            return try await processor
                .fetch(request: request)
        }
        
        return try await processor
            .fetch(request: request.setting(
                value: tokenAccessor.authorization,
                forHeaderName: "Authorization"))
    }
}


@available(*, deprecated, message: "Migrate to the protocol's `RequestProcessor::fetch(request:)` methods.")
extension RequestProcessor {
    
    func process(request: URLRequest) async throws {
        try await fetch(request: request).item
    }
    
    func process<T: Decodable>(request: URLRequest) async throws -> T {
        try await fetch(request: request).item
    }
}


private extension URLRequest {
    var hasAuthorizationHeaderSet: Bool {
        allHTTPHeaderFields?["Authorization"] != nil
    }
}
