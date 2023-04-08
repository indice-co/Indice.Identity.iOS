//
//  ValueStorage.swift
//  
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation

public struct ValueStorageKey {
    let name: String
}

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
