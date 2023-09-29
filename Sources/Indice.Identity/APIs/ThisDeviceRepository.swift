//
//  ThisDeviceService.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation

private extension ValueStorageKey {
    static var deviceIdKey       = ValueStorageKey(name: "device_id_key")
    static var registrationIdKey = ValueStorageKey(name: "registration_id_key")
}


// TODO: See if the INFO needs be a published/bindable item.
internal class ThisDeviceRepositoryImpl: ThisDeviceRepository {

    private let currentDeviceProvider: CurrentDeviceInfoProvider
    private let storage: ValueStorage

    var ids: Ids { get {
        .init(device: deviceIdGetter(),
              registration: registrationIdGetter())
    } }

    var info : Info { get {
        .init(name: currentDeviceProvider.name,
              model: currentDeviceProvider.model,
              osVersion: currentDeviceProvider.osVersion)
    } }
    
    init(storage: ValueStorage, currentDeviceInfoProvider: CurrentDeviceInfoProvider) {
        self.storage = storage
        self.currentDeviceProvider = currentDeviceInfoProvider
    }
    
    func resetIds() {
        storage.clearValue(forKey: .deviceIdKey)
        storage.clearValue(forKey: .registrationIdKey)
    }
    
    func update(registrationId: String?) {
        if let registrationId {
            storage.store(value: registrationId, forKey: .registrationIdKey)
        } else {
            storage.clearValue(forKey: .registrationIdKey)
        }
    }
    
    
    // MARK: Helpers
    
    private func deviceIdGetter() -> String {
        if let deviceId = storage.readValue(forKey: .deviceIdKey) {
            return deviceId
        }
        
        let newDeviceId = UUID().uuidString
        storage.store(value: newDeviceId, forKey: .deviceIdKey)
        
        return newDeviceId
    }
    
    private func registrationIdGetter() -> String? {
        storage.readValue(forKey: .registrationIdKey)
    }
    

    
}

