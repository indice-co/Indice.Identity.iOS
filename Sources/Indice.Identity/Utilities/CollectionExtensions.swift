//
//  CollectionExtensions.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation

extension Collection {
    
    /** Return the collection only when it is not empty. */
    var nonEmpty: Self? {
        guard !isEmpty else {
            return nil
        }
        
        return self
    }
}

extension Collection where Element == Client.Scope {
    
    var value: String {
        self.map(\.value).joined(separator: " ")
    }

    public static var defaultUserScopes: [Element] { [.profile,
                                                      .openId,
                                                      .email,
                                                      .phone,
                                                      .role,
                                                      .offlineAccess,
                                                      .identity] }
}
