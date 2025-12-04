//
//  PKCE.swift
//  Indice_Identity
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//

import Foundation

public struct PKCE {
    public enum ChallengeMethod: String {
        case sha256 = "S256"
    }
    
    public struct Data {
        public let verifier: String
        public let pkce: PKCE
    }
    
    public let challenge: String
    public let nonce: String
    public let challengeMethod : ChallengeMethod
    
    public static func generateData(with challengeMethod: ChallengeMethod = .sha256) -> Data {
        let codeVerifier = CryptoRandom.uniqueId()
        let nonce        = CryptoRandom.randomKeyString()
        let challenge    = CryptoRandom.sha256(codeVerifier)

        let pkce =  PKCE(challenge: challenge,
                         nonce: nonce,
                         challengeMethod: challengeMethod)
        
        return PKCE.Data(verifier: codeVerifier, pkce: pkce)
    }
}
