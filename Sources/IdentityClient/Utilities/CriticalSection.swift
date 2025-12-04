//
//  CriticalSection.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 13/11/25.
//

import Foundation

/// Just a wrapper over a lower level lock
/// **NON RE-ENTRANT**
public final class CriticalSectionLock: @unchecked Sendable {
    
    private var lock = os_unfair_lock()
    
    public init() { }
    
    @inline(__always)
    public func withLock<R>(_ body: () throws -> R) rethrows -> R {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        return try body()
    }
}
