//
//  DeviceUtilities.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation

/**
 Provides info to the Identity client about the user's device that are not accessible without a UI specific lib.
 */
public protocol CurrentDeviceInfoProvider: AnyObject, Sendable {
    /** A custom name of the device - usually a user given one. */
    var name      : String { get }
    /** The model of the device */
    var model     : String { get }
    /** The devices current iOS version */
    var osVersion : String { get }
    
}


#if canImport(UIKit) && canImport(DeviceKit)
import UIKit
import DeviceKit

public final class UIDeviceInfoProvider: CurrentDeviceInfoProvider {
    
    private init() {}
    
    public static let shared = UIDeviceInfoProvider()
    
    public var name: String {
        var devName = UIDevice.current.name
        
        if !devName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return devName
        }
        
        let dev = UIDevice.current
        
        devName =   dev.model + " "
        devName +=  dev.systemName + " "
        devName +=  dev.systemVersion
        
        return devName
    }
    
    public var model: String { "\(Device.current)" }
    public var osVersion: String { "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)" }
}

public extension CurrentDeviceInfoProvider where Self == UIDeviceInfoProvider {
    static var uiDevice: Self { UIDeviceInfoProvider.shared }
}

#endif
