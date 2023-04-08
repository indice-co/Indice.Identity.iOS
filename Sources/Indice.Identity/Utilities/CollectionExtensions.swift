//
//  CollectionExtensions.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation

extension Collection {
    var nonEmpty: Self? {
        guard !isEmpty else {
            return nil
        }
        
        return self
    }
}
