//
//  SecureStorage.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 7/10/25.
//

import Foundation

final public class SecureStorage: Sendable {

    private let service : String
    private let purgeTag: String
    
    public init(
        service : String = "identity.keychain-cache.service",
        purgeTag: String = "identity.keychain-cache.purge-tag"
    ) {
        self.service  = service
        self.purgeTag = purgeTag
    }
    
    @discardableResult
    public func store(key: ValueStorageKey, data: Data) -> Bool {
        store(key: key.name, data: data)
    }
    
    @discardableResult
    public func store(key: String, data: Data) -> Bool {
        let query = [
            kSecClass       .string: kSecClassGenericPassword,
            kSecAttrService .string: service,
            kSecAttrAccount .string: key,
            kSecValueData   .string: data,
            kSecAttrLabel   .string: purgeTag
        ].cfDict
        
        SecItemDelete(query)
        
        let status = SecItemAdd(query, nil)
        return status == errSecSuccess
    }
    
    public func read(key: ValueStorageKey) -> Data? {
        read(key: key.name)
    }
    
    public func read(key: String) -> Data? {
        let query = [
            kSecClass       .string: kSecClassGenericPassword,
            kSecAttrService .string: service,
            kSecAttrAccount .string: key,
            kSecReturnData  .string: true,
            kSecAttrLabel   .string: purgeTag,
            kSecMatchLimit  .string: kSecMatchLimitOne
        ].cfDict
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    @discardableResult
    public func remove(key: ValueStorageKey) -> Bool {
        remove(key: key.name)
    }
    
    @discardableResult
    public func remove(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    @discardableResult
    public func purgeStorage() -> Bool {
        let query: [String: Any] = [
            kSecClass       .string: kSecClassGenericPassword,
            kSecAttrService .string: service,
            kSecAttrLabel   .string: purgeTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
