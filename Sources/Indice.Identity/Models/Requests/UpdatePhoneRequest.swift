//
//  UpdatePhoneRequest.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 28/3/23.
//

import Foundation

public struct UpdatePhoneRequest: Codable {
    public let phoneNumber: String
    public let deliveryChannel: TotpDeliveryChannel?
    
    public init(phoneNumber: String, deliveryChannel: TotpDeliveryChannel?) {
        self.phoneNumber = phoneNumber
        self.deliveryChannel = deliveryChannel
    }
}
