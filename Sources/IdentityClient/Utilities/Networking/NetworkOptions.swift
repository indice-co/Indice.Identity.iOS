//
//  NetworkOptions.swift
//
//
//  Created by Nikolas Konstantakopoulos on 29/7/24.
//

import Foundation

public struct NetworkOptions: Sendable {
    let processorBuilder : @Sendable () -> RequestProcessor
    let errorParser : ErrorParser
    
    public init(
        processorBuilder: @Sendable @escaping () -> RequestProcessor,
        errorParser: ErrorParser
    ) {
        self.processorBuilder = processorBuilder
        self.errorParser      = errorParser
    }
    
    public init(
        errorParser: ErrorParser,
        processorBuilder: @Sendable @escaping () -> RequestProcessor,
    ) {
        self.processorBuilder = processorBuilder
        self.errorParser      = errorParser
    }

}

