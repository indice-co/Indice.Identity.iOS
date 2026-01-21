//
//  UIDeviceInfoProvider.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 21/1/26.
//

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
