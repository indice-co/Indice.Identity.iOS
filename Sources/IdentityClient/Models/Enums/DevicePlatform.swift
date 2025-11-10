//
//  DevicePlatform.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public enum DevicePlatform: String, Codable, Sendable, CaseIterable {
    case _none = "None"
    case android = "Android"
    case ios = "iOS"
    case windows = "Windows"
    case macOS = "MacOS"
    case linux = "Linux"
}
