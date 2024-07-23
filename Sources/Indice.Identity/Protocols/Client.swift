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
    
    public struct Scope {
        let value: String
    }
    
    /** Client urls. Authorization Urls and Post Logout url. */
    public struct Urls {
        public var authorization: String? = nil
        public var postLogout: String? = nil
        
        public init(authorization: String? = nil, postLogout: String? = nil) {
            self.authorization = authorization
            self.postLogout = postLogout
        }
        
        ///Creates a Urls based on the default common values used most of the time
        ///
        ///It is the equivalent of:
        ///
        ///      Urls.init(authorization: "\(redirectScheme)://auth-callback",
        ///                postLogout:    "\(redirectScheme)://post-logout")
        public init(commonForRedirectScheme redirectScheme: String) {
            self.authorization = "\(redirectScheme)://auth-callback"
            self.postLogout    = "\(redirectScheme)://post-logout"
        }
    }
    
    /** Client ID */
    public let id         : String
    /** Client Secret - Creating a public client deems the secret redundant, */
    public let secret     : String?
    /** Client Scope */
    public let userScope  : [Scope]
    /** Client Scope */
    public let appScope   : [Scope]
    /** Client urls. Authorization Urls and Post Logout url. */
    public let urls       : Urls
    
    @available(*, deprecated, message: "Use the new ctor that accepts a collection of Client.Scope")
    public init(id: String, secret: String?, userScope: String, appScope: String, urls: Urls) {
        func splitScopes(_ scopes: String) -> [Client.Scope] {
            scopes.components(separatedBy: .whitespaces).map(Client.Scope.init(value:))
        }
        
        self.id = id
        self.secret = secret
        self.userScope = splitScopes(userScope)
        self.appScope = splitScopes(appScope)
        self.urls = urls
    }
    
    public init(id: String, secret: String?, userScope: [Scope], appScope: [Scope], urls: Urls) {
        self.id = id
        self.secret = secret
        self.userScope = userScope
        self.appScope = appScope
        self.urls = urls
    }
}


extension Client.Scope: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.value = value
    }
}

extension Client.Scope {
    public static let profile          : Self = "profile"
    public static let openId           : Self = "openid"
    public static let email            : Self = "email"
    public static let phone            : Self = "phone"
    public static let role             : Self = "role"
    public static let offlineAccess    : Self = "offline_access"
    public static let identity         : Self = "identity"
}


public extension Client {
    /** Provides the basic auth header for the specific client */
    var basicAuth: String {
       "Basic " +
            (id + ":" + (secret ?? ""))
                .data(using: .utf8)!
                .base64EncodedString()
    }
}
