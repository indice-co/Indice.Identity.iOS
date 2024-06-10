//
//  ExtendedProblemDetails.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 7/6/24.
//

import Foundation
import SwiftyJSON
import IndiceNetworkClient

public struct ExtendedProblemDetails: NetworkError {
    
    static let defaultErrorText = "Unknown Business Error Occurred"
    
    public let detail: String?
    public let errors: [String:[String]]?
    public let status: Int?
    public let title: String?
    public let type: String?
    public let code: String?
    
    public let error_description: String?
    
    public let authorization_details: JSON?
    
    // Conformance to NetworkError Protocol
    public var description: String {
        get {
            if let existingErrors = errors {
                return existingErrors
                    .flatMap { $0.value }
                    .joined(separator: "\n")
            }
            return detail ?? error_description ?? Self.defaultErrorText
        }
    }
}
