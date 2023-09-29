//
//  ValueStorage.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation

/** 
 A simple wrapper around a string to be used as a key with the ``ValueStorage``.
 
 ```
 extension ValueStorageKey {
 
     static var someKeyName: ValueStorageKey = .init(name: "some_key_name")
 }
 
 let storage = UserDefaults.standard
 
 storage.store(value: true, forKey: .someKeyName)
 let someKeyValue = storage.readBool(forKey: .someKeyName)
 
 ```
 
 Main reasons for this existing is:
    - Type the key name once
    - The **.value** syntax, is faster to write as you omit the class type!!
 */
public struct ValueStorageKey {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}

/**
 A storage interface that can store and read values.
 Its purpose is to be used by the ``IdentityClient`` to store persistent values.

 UseDefaults conform to this protocol, and are used as the default implementation within the library.
 */
public protocol ValueStorage: AnyObject {
    typealias Key = ValueStorageKey
    
    func store(value: Any, forKey: Key)
    
    func readValue (forKey: Key) -> String?
    func readBool  (forKey: Key) -> Bool?
    func readObject(forKey: Key) -> Any?
    
    func clearValue(forKey: Key)
}


extension UserDefaults: ValueStorage {
    
    public func store(value: Any, forKey key: ValueStorage.Key) {
        self.set(value, forKey: key.name)
    }
    
    public func readValue(forKey key: ValueStorage.Key) -> String? {
        self.string(forKey: key.name)
    }
    
    public func readBool(forKey key: ValueStorage.Key) -> Bool? {
        self.bool(forKey: key.name)
    }
    
    public func readObject(forKey key: Key) -> Any? {
        self.object(forKey: key.name)
    }
    
    public func clearValue(forKey key: Key) {
        self.removeObject(forKey: key.name)
    }
}
