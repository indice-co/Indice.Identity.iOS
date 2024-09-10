//
//  NetworkOptions.swift
//
//
//  Created by Nikolas Konstantakopoulos on 29/7/24.
//

import Foundation

public struct NetworkOptions {
    let processor   : () -> RequestProcessor
    let errorParser : ErrorParser
    
    public init(processor: @escaping () -> RequestProcessor, errorParser: ErrorParser) {
        self.processor = processor
        self.errorParser = errorParser
    }
}

