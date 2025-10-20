//
//  ThisDeviceService.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation

private extension ValueStorageKey {
    static let deviceIdKey       = ValueStorageKey(name: "device_id_key")
    static let registrationIdKey = ValueStorageKey(name: "registration_id_key")
}


// TODO: See if the INFO needs be a published/bindable item.
internal class ThisDeviceRepositoryImpl: ThisDeviceRepository {
    private let currentDeviceProvider: CurrentDeviceInfoProvider
    private let secureStorage: SecureStorage
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
    
    init(storage: ValueStorage,
         secureStorage: SecureStorage,
         currentDeviceInfoProvider: CurrentDeviceInfoProvider) {
        self.storage = storage
        self.secureStorage = secureStorage
        self.currentDeviceProvider = currentDeviceInfoProvider
    }
    
    func resetIds() {
        storage.clearValue(forKey: .deviceIdKey)
        storage.clearValue(forKey: .registrationIdKey)
    }
    
    @discardableResult
    func update(registrationId: String?) -> Bool {
        return if let registrationId {
            secureStorage.store(key: ValueStorageKey.registrationIdKey.name, data: Data(registrationId.utf8))
        } else {
            secureStorage.remove(key: ValueStorageKey.registrationIdKey.name)
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
        guard let data = secureStorage.read(key: ValueStorageKey.registrationIdKey.name) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    

    
}

