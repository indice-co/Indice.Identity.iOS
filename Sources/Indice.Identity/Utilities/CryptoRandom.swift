//
//  CryptoRandomHelper.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation
import CryptoKit

final class CryptoRandom {
    
    static let uniqueIdLength = 32
    static let randomStringLength = 64
    
    class func base64URLEncode<S>(bytes: S) -> String where S : Sequence, UInt8 == S.Element {
        Data(bytes)
            .base64EncodedString()                    // Regular base64 encoder
            .replacingOccurrences(of: "=", with: "")  // Remove any trailing '='s
            .replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
            .replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
            .trimmingCharacters(in: .whitespaces)
    }
    
    
    class func randomKey(ofLength: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: ofLength)
        let _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        return bytes
    }
    
    class func uniqueId() -> String {
        return randomKeyString(ofLength: uniqueIdLength)
    }
    
    class func randomKeyString(ofLength: Int = randomStringLength) -> String {
        let bytes = randomKey(ofLength: ofLength)
        return base64URLEncode(bytes: bytes)
    }
    
    class func sha256(_ value: String, encoding: String.Encoding = .utf8) -> String {
        return sha256(value.data(using: encoding)!)
    }
    
    class func sha256(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return base64URLEncode(bytes: hash)
    }
}
