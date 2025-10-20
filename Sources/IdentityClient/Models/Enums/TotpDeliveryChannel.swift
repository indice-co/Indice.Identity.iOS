//
//  TotpDeliveryChannel.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 22/3/23.
//

import Foundation

public enum TotpDeliveryChannel: String, Codable, CaseIterable {
    case sms = "Sms"
    case email = "Email"
    case telephone = "Telephone"
    case viber = "Viber"
    case etoken = "EToken"
    case pushNotification = "PushNotification"
    case _none = "None"
}
