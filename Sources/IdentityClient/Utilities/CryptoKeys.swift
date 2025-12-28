//
//  CryptoKeys.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

@preconcurrency
import Foundation

import CryptoKit

internal struct SecKeyTags {
    static let devicePin   = "indice.identity.devicepin.tag".data(using: .utf8)!
    static let fingerprint = "indice.identity.fingerprint.tag".data(using: .utf8)!
}

internal extension CryptoUtils.TagData {
    static var devicePin   : CryptoUtils.TagData { SecKeyTags.devicePin   }
    static var fingerprint : CryptoUtils.TagData { SecKeyTags.fingerprint }
}


protocol KeyPair: Sendable {
    var `public`  : SecKey { get }
    var `private` : SecKey { get }
}

final class CryptoUtils {
    enum Error: Swift.Error {
        case missingKey(_ status: OSStatus)
        case reason(_ error: Swift.Error)
    }
    
    
    typealias TagData = Data
    
    private struct InnerKeyPair: KeyPair  {
        let `public`  : SecKey
        let `private` : SecKey
    }
    
    class func challenge(for verifier: String, encoding: String.Encoding = .utf8) -> String {
        let data = verifier.data(using: encoding)!
        let hash = SHA256.hash(data: data)
        
        return CryptoRandom.base64URLEncode(bytes: hash)
    }
    
    class func createKeyPair(locked: Bool, tagged tag: TagData? = nil) throws(Error) -> KeyPair {
        let tagData = tag ?? SecHelper.createTag(lockedKey: locked)
        let attrs   = SecHelper.createAttributes(tagged: tagData, bioLocked: locked)
        
        deleteKeyPair(locked: locked)
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attrs as CFDictionary, &error) else {
            throw .reason(error!.takeRetainedValue() as Swift.Error)
        }
        
        let publicKey  = SecKeyCopyPublicKey(privateKey)!
        
        return InnerKeyPair(public: publicKey, private: privateKey)
    }

    class func loadKeyPair(locked: Bool, tagged tag: TagData? = nil) throws(Error) -> KeyPair {
        let tagData = tag ?? SecHelper.createTag(lockedKey: locked)
        let query = SecHelper.createQuery(tagData: tagData, locked: locked)
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw .missingKey(status)
        }
        
        let privateKey = item as! SecKey
        let publicKey  = SecKeyCopyPublicKey(privateKey)!
        
        return InnerKeyPair(public: publicKey, private: privateKey)
    }

    @discardableResult
    class func deleteKeyPair(locked: Bool, tagged tag: TagData? = nil) -> Bool {
        let tagData = tag ?? SecHelper.createTag(lockedKey: locked)
        let query = SecHelper.createQuery(tagData: tagData, locked: locked)
        let status = SecItemDelete(query as CFDictionary)
        
        return status == noErr
    }
    
    class func pem(for keyPair: KeyPair) throws(Error) -> String {
        let publicKeyReference = keyPair.public
        
        var error: Unmanaged<CFError>? = nil
        let keyBytes = SecKeyCopyExternalRepresentation(publicKeyReference, &error)
        if let error = error?.takeRetainedValue() {
            throw .reason(error)
        }
        
        return SecHelper.convertDerToPem(from: keyBytes! as Data)
    }
    
    class func sign(string: String, with keyPair: KeyPair) throws(Error) -> String {
        return try sign(data: string.data(using: .utf8)!, with: keyPair)
            .base64EncodedString()
    }
    
    class func sign(data: Data, with keyPair: KeyPair) throws(Error) -> Data {
        
        var response: Unmanaged<CFError>? = nil
        let signedData = SecKeyCreateSignature(keyPair.private, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &response)
        
        if let error = response?.takeRetainedValue() {
            throw .reason(error)
        } else {
            return signedData! as Data
        }
    }

    class func prepare(pin: String, withDeviceId deviceId: String, and keys: KeyPair) throws(Error) -> String {
        let value  = "\(pin)-\(deviceId)"
        let signed = try sign(string: value, with: keys)
        let bytes  = SHA256.hash(data: signed.data(using: .utf8)!)

        return Data(bytes).base64EncodedString()
    }
    
}


// MARK: - Private helpers

internal extension CFString {
    var string : String { get { self as String } }
}

internal extension Dictionary where Key == String, Value == Any {
    var cfDict : CFDictionary { get { self as CFDictionary } }
}
    
private class SecHelper {
    
    static private let pemRowSize  = 65
    static private let privateKeySize = 4096
    static private let pinKeyTag = "gr.indice.samples.flows.keys.sec-keys"
    static private let bioKeyTag = "gr.indice.samples.flows.bio-sec-keys"
    
    private init() {}
    
    class func createTag(lockedKey: Bool) -> Data {
        (lockedKey ? bioKeyTag : pinKeyTag).data(using: .utf8)!
    }
    
    class func createAccess() -> SecAccessControl {
        SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                        [.biometryCurrentSet], nil)! // nil error - ignore error!
    }
    
    
    class func createAttributes(tagged tag: CryptoUtils.TagData, bioLocked: Bool) -> [String: Any] {
        
        let keyAttrs: [String: Any] = {
            var tmpAttrs: [String: Any] = [kSecAttrIsExtractable  .string: true,
                                           kSecAttrIsPermanent    .string: true,
                                           kSecAttrApplicationTag .string: tag]
            
            if bioLocked {
                tmpAttrs[kSecAttrAccessControl.string] = createAccess()
            }
            
            return tmpAttrs
        }()
        
        return [kSecAttrKeyType       .string: kSecAttrKeyTypeRSA,
                kSecAttrKeySizeInBits .string: privateKeySize,
                kSecPrivateKeyAttrs   .string: keyAttrs.cfDict]
    }
 
    class func createQuery(tagData: CryptoUtils.TagData, locked : Bool) -> [String: Any] {
        [kSecClass              .string: kSecClassKey,
         kSecAttrApplicationTag .string: tagData,
         kSecAttrKeyType        .string: kSecAttrKeyTypeRSA,
         kSecReturnRef          .string: true]
    }
    
    class func createLoadQuery(tagData: CryptoUtils.TagData, locked: Bool) -> [String: Any] {
        [kSecClass              .string: kSecClassKey,
         kSecAttrApplicationTag .string: tagData,
         kSecAttrKeyType        .string: kSecAttrKeyTypeRSA,
         kSecAttrKeyClass       .string: kSecAttrKeyClassPrivate,
         kSecReturnRef          .string: true]
    }
    
    class func convertDerToPem(from DERData: Data) -> String {
        func components(ofString string: String) -> [String] {
            return stride(from: 0, to: string.count, by: pemRowSize).map { offset in
                let start = string.index(string.startIndex,
                                         offsetBy: offset)
                
                let end = string.index(start,
                                       offsetBy: pemRowSize,
                                       limitedBy: string.endIndex) ?? string.endIndex
                
                return String(string[start..<end])
            }
        }
        
        let base64String = DERData.base64EncodedString()
        let lines = components(ofString: base64String)
        let joinedLines = lines.joined(separator: "\n")
        
        return  "-----BEGIN RSA PUBLIC KEY-----\n"
                + joinedLines
                + "\n-----END RSA PUBLIC KEY-----"
    }
    
}
