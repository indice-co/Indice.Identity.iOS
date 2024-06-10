//
//  Grant.swift
//  Indice_Identity
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//

import Foundation
import SwiftyJSON

/**
  OAuth2 Grant used to authorize a user or client.
 
  Each type carries parameters relevant to their grantType value.
 */
public protocol OAuth2Grant {
    typealias Params = [String: Any]
    
    /** The grant flow type name */
    static var grantType: String { get }
    
    /** The OAuth2Grant params.
     
     Any extra parameter that the grant needs.
     The param dictionary will be form-encoded.
     */
    var params: Params { get }
    
    var isUserGrant: Bool { get }
}

public extension OAuth2Grant {
    /**
     Return true if the grant will authorize a User, or false if the grant will authorize a client.
     
     If this value returns "true" the final grant generation will use the current client's [Client.userScope](Client.userScope)
     else it will use [Client.appScope](Client.appScope) as the scope property of the grant.
    
     The default value is true.
     For now, only the ```ClientCredentialsGrant``` returns false.
     */
    var isUserGrant: Bool { true }
    
    var grantType: String { Self.grantType }
}


// MARK: - Internal Utilities

internal extension OAuth2Grant {

    /** 
    Used to add `authorization_details` to a `OAuth2Grant`
     
    As `authorization_details` is a dynamic objects, and not always present,
    the property is not a part of the base protocol.
     */
    func with(authorizationDetails details: JSON) -> OAuth2Grant {
        let extras = ["authorization_details": details]
        
        return OAuthParamsWrapper(parent: self, extras: extras)
    }
}


internal extension OAuth2Grant {
    
    /** Add the default `Client` properties to a `OAuth2Grant.Params` */
    func with(client: Client) -> OAuth2Grant {
        let scope = self.isUserGrant
                  ? client.userScope
                  : client.appScope
        
        let extras: Params = ["scope"         : scope,
                              "client_id"     : client.id,
                              "client_secret" : client.secret]
                                  .compactMapValues { $0 }
        
        return OAuthParamsWrapper(parent: self, extras: extras)
    }
    
    /** 
    Add the default ```ThisDeviceIds``` properties to a ```OAuth2Grant.Params```
     */
    func with(deviceIds: ThisDeviceIds) -> OAuth2Grant {
        let extras: Params = ["device_id"       : deviceIds.device,
                              "registration_id" : deviceIds.registration]
                                  .compactMapValues { $0 }
        
        return OAuthParamsWrapper(parent: self, extras: extras)
    }
}



/** A wrapper over an ordinary `OAuth2Grant`.
    It's `params` getter will return its original ones and the `authorization_details`.
 */
private struct OAuthParamsWrapper<Parent: OAuth2Grant>: OAuth2Grant {
    static var grantType: String { Parent.grantType }
    
    let parent: Parent
    let extras: Params
    
    var params: Params {
        parent
            .params
            .merging(extras) { _, v in v }
            .compactMapValues { $0 }
    }
}
