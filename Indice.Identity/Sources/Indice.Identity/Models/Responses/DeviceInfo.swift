//
//  DeviceInfo.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation

public struct DeviceInfo: Codable {
    
    public var deviceId: String? = nil
    public var name: String? = nil
    public var platform: DevicePlatform? = nil
    public var isPushNotificationsEnabled: Bool? = nil
    public var supportsPinLogin: Bool? = nil
    public var supportsFingerprintLogin: Bool? = nil
    public var model: String? = nil
    public var osVersion: String? = nil
    public var data: String? = nil
    public var dateCreated: Date? = nil
    public var lastSignInDate: Date? = nil
    public var isTrusted: Bool? = nil
    public var trustActivationDate: Date? = nil
    public var canActivateDeviceTrust: Bool? = nil
    public var clientType: DeviceClientType? = nil
}
