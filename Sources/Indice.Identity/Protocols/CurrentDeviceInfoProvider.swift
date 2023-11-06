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
public protocol CurrentDeviceInfoProvider: AnyObject {
    /** A custom name of the device - usually a user given one. */
    var name      : String { get }
    /** The model of the device */
    var model     : String { get }
    /** The devices current iOS version */
    var osVersion : String { get }
    
}
