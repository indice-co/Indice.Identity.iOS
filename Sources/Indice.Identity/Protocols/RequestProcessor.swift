//
//  RequestProcessor.swift
//
//
//  Created by Nikolas Konstantakopoulos on 5/11/23.
//

import Foundation
import IndiceNetworkClient

public protocol RequestProcessor: AnyObject {
    
    func process(request: URLRequest) async throws
    
    func process<T: Decodable>(request: URLRequest) async throws -> T
}


extension NetworkClient: RequestProcessor {
    public func process(request: URLRequest) async throws {
        try await fetch(request: request)
    }
    
    public func process<T>(request: URLRequest) async throws -> T where T : Decodable {
        return try await fetch(request: request)
    }
    
}

