//
//  CryptoKeys.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

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


protocol KeyPair {
    var `public`  : SecKey { get }
    var `private` : SecKey { get }
}

final class CryptoUtils {
    
    typealias TagData = Data
    
    private struct InnerKeyPair : KeyPair  {
        let `public`  : SecKey
        let `private` : SecKey
    }
    
    enum KeyResult {
        case value(pair: KeyPair)
        case error(code: OSStatus)
    }
    
    class func challenge(for verifier: String, encoding: String.Encoding = .utf8) -> String {
        let data = verifier.data(using: encoding)!
        let hash = SHA256.hash(data: data)
        
        return CryptoRandom.base64URLEncode(bytes: hash)
    }
    
    class func createKeyPair(locked: Bool, tagged tag: TagData? = nil) throws -> KeyPair {
        let tagData = tag ?? SecHelper.createTag(lockedKey: locked)
        let attrs   = SecHelper.createAttributes(tagged: tagData, bioLocked: locked)
        
        deleteKeyPair(locked: locked)
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attrs as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        let publicKey  = SecKeyCopyPublicKey(privateKey)!
        
        return InnerKeyPair(public: publicKey, private: privateKey)
    }

    class func loadKeyPair(locked: Bool, tagged tag: TagData? = nil) -> KeyResult {
        let tagData = tag ?? SecHelper.createTag(lockedKey: locked)
        let query = SecHelper.createQuery(tagData: tagData, locked: locked)
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            print("keychain don't have private key (\(status)")
            return .error(code: status)
        }
        
        let privateKey = item as! SecKey
        let publicKey  = SecKeyCopyPublicKey(privateKey)!
        
        return .value(pair: InnerKeyPair(public: publicKey, private: privateKey))
    }

    @discardableResult
    class func deleteKeyPair(locked: Bool, tagged tag: TagData? = nil) -> Bool {
        let tagData = tag ?? SecHelper.createTag(lockedKey: locked)
        let query = SecHelper.createQuery(tagData: tagData, locked: locked)
        let status = SecItemDelete(query as CFDictionary)
        
        return status == noErr
    }
    
    class func pem(for keyPair: KeyPair) throws -> String {
        let publicKeyReference = keyPair.public
        
        var error: Unmanaged<CFError>? = nil
        let keyBytes = SecKeyCopyExternalRepresentation(publicKeyReference, &error)
        if let error = error?.takeRetainedValue() { throw error }
        
        return SecHelper.convertDerToPem(from: keyBytes! as Data)
    }
    
    class func sign(string: String, with keyPair: KeyPair) throws -> String {
        return try sign(data: string.data(using: .utf8)!, with: keyPair)
            .base64EncodedString()
    }
    
    class func sign(data: Data, with keyPair: KeyPair) throws -> Data {
        
        var response: Unmanaged<CFError>? = nil
        let signedData = SecKeyCreateSignature(keyPair.private, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &response)
        
        if let error = response?.takeRetainedValue() {
            throw error
        } else {
            return signedData! as Data
        }
    }

    class func prepare(pin: String, withDeviceId deviceId: String, and keys: KeyPair) throws -> String {
        let value  = "\(pin)-\(deviceId)"
        let signed = try sign(string: value, with: keys)
        let bytes  = SHA256.hash(data: signed.data(using: .utf8)!)

        return Data(bytes).base64EncodedString()
    }
    
}


// MARK: - Private helpers

fileprivate extension CFString {
    var string : String { get { self as String } }
}

fileprivate extension Dictionary where Key == String, Value == Any {
    var cfDict : CFDictionary { get { self as CFDictionary } }
}
    
private class SecHelper {
    
    static private let secKeyClass = kSecClassKey
    static private let secKeyType  = kSecAttrKeyTypeRSA
    
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
        
        return [kSecAttrKeyType       .string: secKeyType,
                kSecAttrKeySizeInBits .string: privateKeySize,
                kSecPrivateKeyAttrs   .string: keyAttrs.cfDict]
    }
 
    class func createQuery(tagData: CryptoUtils.TagData, locked : Bool) -> [String: Any] {
        [kSecClass              .string: secKeyClass,
         kSecAttrApplicationTag .string: tagData,
         kSecAttrKeyType        .string: secKeyType,
         kSecReturnRef          .string: true]
    }
    
    class func createLoadQuery(tagData: CryptoUtils.TagData, locked: Bool) -> [String: Any] {
        [kSecClass              .string: secKeyClass,
         kSecAttrApplicationTag .string: tagData,
         kSecAttrKeyType        .string: secKeyType,
         kSecAttrKeyClass       .string: kSecAttrKeyClassPrivate,
         kSecReturnRef          .string: true]
    }
    
    class func convertDerToPem(from derData: Data) -> String {
        func components(ofString string: String, withLength length: Int) -> [String] {
            return stride(from: 0, to: string.count, by: length).map {
                let start = string.index(string.startIndex, offsetBy: $0)
                let end = string.index(start, offsetBy: length, limitedBy: string.endIndex) ?? string.endIndex
                return String(string[start..<end])
            }
        }
        
        let base64String = derData.base64EncodedString()
        let lines = components(ofString: base64String, withLength: 65)
        let joinedLines = lines.joined(separator: "\n")
        
        return ("-----BEGIN RSA PUBLIC KEY-----\n" + joinedLines + "\n-----END RSA PUBLIC KEY-----")
    }
    
}
