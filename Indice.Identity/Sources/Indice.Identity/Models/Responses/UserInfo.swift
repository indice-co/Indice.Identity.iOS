//
//  UserInfo.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 27/3/23.
//

import Foundation

public struct UserInfo: Codable {
    public let id: String?
    public let firstName: String?
    public let lastName: String?
    public let emailConfirmed: Bool?
    public let phoneNumberConfirmed: Bool?
    public let lockoutEnabled: Bool?
    public let twoFactorEnabled: Bool?
    public let createDate: Date?
    public let lockoutEnd: Date?
    public let email: String?
    public let phoneNumber: String?
    public let userName: String?
    public let blocked: Bool?
    public let passwordExpirationPolicy: PasswordExpirationPolicy?
    public let isAdmin: Bool?
    public let accessFailedCount: Int?
    public let lastSignInDate: Date?
    public let passwordExpirationDate: Date?
}
