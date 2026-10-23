//
//  IdentityClientExt.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 21/1/26.
//


#if canImport(UIKit) && canImport(DeviceKit)
import Foundation

public extension IdentityClient {
    // MARK: - Init
    public convenience init(
                client          : Client,
                configuration   : IdentityConfig,
                options         : IdentityClient.Options = .init(maxTrustedDevicesCount: 1),
                valueStorage    : ValueStorage = UserDefaults.standard,
                secureStorage   : SecureStorage = SecureStorage(),
                tokenStorage    : TokenStorage = .ephemeral,
                networkOptions  : NetworkOptions) {
        self.init(client          : client,
                  configuration   : configuration,
                  options         : options,
                  currentDeviceInfoProvider: .uiDevice,
                  valueStorage    : valueStorage,
                  secureStorage   : secureStorage,
                  tokenStorage    : tokenStorage,
                  networkOptions  : networkOptions)
    }
}
#endif
