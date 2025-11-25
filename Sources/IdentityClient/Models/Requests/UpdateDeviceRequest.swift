//
//  UpdateDeviceRequest.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation

public struct UpdateDeviceRequest: Codable, Sendable {   
    public var name: String
    public var isPushNotificationsEnabled: Bool?
    public var tags: [String]?
    public var pnsHandle: String?
    public var model: String?
    public var osVersion: String?
    public var data: String?
}
