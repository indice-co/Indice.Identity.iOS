//
//  TrustDeviceMode.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation

public enum TrustDeviceMode: String, Codable, CaseIterable {
    case biometric = "fingerprint"
    case pin = "pin"
}
