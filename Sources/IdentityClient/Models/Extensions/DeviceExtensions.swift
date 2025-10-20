//
//  DeviceExtensions.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation

internal extension UpdateDeviceRequest {
    
    static func from(service: ThisDeviceRepository, pnsHandle: String?, customTags: [String]? = nil) -> UpdateDeviceRequest{
        // let ids  = service.ids
        let info = service.info
        
        return .init(name: info.name,
                     isPushNotificationsEnabled: pnsHandle != nil,
                     tags: customTags,
                     pnsHandle: pnsHandle,
                     model: info.model,
                     osVersion: info.osVersion,
                     data: nil)
    }
}


internal extension CreateDeviceRequest {
    
    static func from(service: ThisDeviceRepository, pnsHandle: String?, customTags: [String]? = nil) -> CreateDeviceRequest {
        let ids  = service.ids
        let info = service.info
        
        return .init(deviceId: ids.device,
                     pnsHandle: pnsHandle,
                     name: info.name,
                     platform: .ios,
                     clientType: .native,
                     tags: customTags,
                     model: info.model,
                     osVersion: info.osVersion,
                     data: nil)
    }
}
