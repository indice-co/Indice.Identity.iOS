//
//  Client.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

/**
 The Client properties, as setup in the IdentityServer.
 */
public struct Client {
    
    /** Client urls. Authorization Urls and Post Logout url. */
    public struct Urls {
        public var authorization: String? = nil
        public var postLogout: String? = nil
        
        public init(authorization: String? = nil, postLogout: String? = nil) {
            self.authorization = authorization
            self.postLogout = postLogout
        }
    }
    
    /** Client ID */
    public let id     : String
    /** Client Secret - Creating a public client deems the secret redundant, */
    public let secret : String?
    /** Client Scope */
    public let scope  : String
    /** Client urls. Authorization Urls and Post Logout url. */
    public let urls   : Urls
    
    public init(id: String, secret: String?, scope: String, urls: Urls = .init()) {
        self.id = id
        self.secret = secret
        self.scope = scope
        self.urls = urls
    }
}


public extension Client {
    /** Provides the basic auth header for the specific client */
    var basicAuth: String { get {
       "Basic " +
            (id + ":" + (secret ?? ""))
                .data(using: .utf8)!
                .base64EncodedString()
    } }
}
