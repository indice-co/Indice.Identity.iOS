//
//  DeviceInfo.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation

public struct DeviceInfo: Codable, Equatable {
    
    public var deviceId: String?
    public var name: String?
    public var platform: DevicePlatform?
    public var isPushNotificationsEnabled: Bool?
    public var supportsPinLogin: Bool?
    public var supportsFingerprintLogin: Bool?
    public var model: String?
    public var osVersion: String?
    public var data: String?
    public var dateCreated: Date?
    public var lastSignInDate: Date?
    public var isTrusted: Bool?
    public var trustActivationDate: Date?
    public var canActivateDeviceTrust: Bool?
    public var clientType: DeviceClientType?
}
