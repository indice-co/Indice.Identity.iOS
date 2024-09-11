//
//  EncodableExtensions.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public extension Encodable {
    /// Return the object as a Dictionary. Mainly used to aid creating a x-www-form-urlencoded payload.
    var asDict : [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return nil }
        return json
    }
}
