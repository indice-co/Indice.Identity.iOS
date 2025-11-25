//
//  ResultSet.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 8/4/23.
//

import Foundation

public struct ResultSet<T: Codable>: Codable, Sendable where T: Sendable {
    public let count: Int?
    public let items: [T]?
}
