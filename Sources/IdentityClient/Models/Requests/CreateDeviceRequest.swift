//
//  CreateDeviceRequest.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation

public struct CreateDeviceRequest: Codable {
    public var deviceId: String
    public var pnsHandle: String?
    public var name: String
    public var platform: DevicePlatform
    public var clientType: DeviceClientType?
    public var tags: [String]?
    public var model: String?
    public var osVersion: String?
    public var data: String?
}
