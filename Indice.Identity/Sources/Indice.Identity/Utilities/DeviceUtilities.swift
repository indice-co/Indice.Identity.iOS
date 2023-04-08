//
//  DeviceUtilities.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import UIKit
import DeviceKit

public class DeviceUtilities {
    
    static var name: String {
        get {
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
    }
    
    static var model: String {
        get { "\(Device.current)" }
    }
    
    static var osVersion: String {
        get { "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)" }
    }
    
    
}
