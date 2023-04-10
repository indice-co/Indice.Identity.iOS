//
//  UserInfo.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation

public struct UserInfo: Codable {
    public let sub: String
    public let name: String?
    public let given_name: String?
    public let family_name: String?
    public var profile_id: String?
    public var otp_channel: TotpDeliveryChannel?
    public var otp_channel_disabled: String?
    public var password_expiration_date: Date?
    public var password_expiration_policy: PasswordExpirationPolicy?
    public var admin: Bool?
    public var preferred_username: String?
    public var email: String?
    public var email_verified: Bool?
    public var phone_number: String?
    public var phone_number_verified: Bool?
    public var max_devices_count: String?
}
