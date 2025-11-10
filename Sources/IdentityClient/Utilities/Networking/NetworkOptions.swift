//
//  NetworkOptions.swift
//
//
//  Created by Nikolas Konstantakopoulos on 29/7/24.
//

import Foundation

public struct NetworkOptions: Sendable {
    let processor   : @Sendable () -> RequestProcessor
    let errorParser : ErrorParser
    
    public init(processor: @Sendable @escaping () -> RequestProcessor, errorParser: ErrorParser) {
        self.processor = processor
        self.errorParser = errorParser
    }
}

