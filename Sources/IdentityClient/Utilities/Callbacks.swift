//
//  Callbacks.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 10/4/23.
//

import Foundation

public struct CallbackType {
    public enum OtpResult: Equatable {
        case aborted
        case submit(value: String)
        
        var isAborted: Bool {
            switch self {
            case .aborted: return true
            case .submit : return false
            }
        }
        
        var otpValue: String? {
            switch self {
            case .aborted           : return nil
            case .submit(let value) : return value
            }
        }
    }
    
    public enum DeviceSwapResult: Equatable {
        case swap(deviceInfo: DeviceInfo)
        case aborted
    }
    
    public typealias OtpProvider = (_ needsOtp: Bool) async -> OtpResult
    
    public typealias ContinuationAsync = () async -> ()
    
    public typealias DeviceSelection = ([DeviceInfo]) async -> DeviceSwapResult
}
