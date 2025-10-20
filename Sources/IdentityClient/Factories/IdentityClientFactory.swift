//
//  IdentityClientFactory.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 6/11/23.
//

import Foundation



final public class IdentityClientFactory {
    
    @available(*, unavailable)
    private init() {}
    
    /**
     Create an instance of the IdentityClient.
     
     - Parameter client: The Client info as set in the `IdentityServer`
     - Parameter configuration: Properties regarding the `IdentityServer` installation
     - Parameter currentDeviceInfoProvider: Provide in implementation of the ``CurrentDeviceInfoProvider``
     - Parameter valueStorage: (optional) Provide a custom implementation of a persistent storage. Default is `UserDefaults.standard`.
     - Parameter tokenStorage: (optional) Provide a custom TokenStorage implementation. Default is `TokenStorage.ephemeral`.
     - Parameter networkClientBuilder: (optional but suggested) Provide a builder for a ``NetworkClient``. Mainly used to add interceptors that use the accessToken.
                                   By default the builder adds a ``AuthorizationHeaderInterceptor`` and ``AuthorizingInterceptor`` that add any existing
                                   access tokens from the TokenStorage as Authorization header and try requesting a valid access token when a 401 error code is found, respectively.
     */
    public static func create(
        client: Client,
        configuration: IdentityConfig,
        currentDeviceInfoProvider: CurrentDeviceInfoProvider,
        valueStorage: ValueStorage,
        tokenStorage: TokenStorage,
        networkOptionsBuilder: @escaping ((IdentityClient) -> NetworkOptions)) -> IdentityClient {
            IdentityClientImpl(
                client: client,
                configuration: configuration,
                currentDeviceInfoProvider: currentDeviceInfoProvider,
                valueStorage: valueStorage,
                tokenStorage: tokenStorage,
                networkOptionsBuilder: networkOptionsBuilder)
    }
    
    
    /**
     Create an instance of the IdentityClient.
     
     - Parameter baseUrl: Initializes the ``IdentityClient`` with a configuration (``IdentityConfig``) that uses default endpoints.
     - Parameter client: The Client info as set in the `IdentityServer`
     - Parameter currentDeviceInfoProvider: Provide in implementation of the ``CurrentDeviceInfoProvider``
     - Parameter networkClientBuilder: (optional but suggested) Provide a builder for a ``NetworkClient``. Mainly used to add interceptors that use the accessToken.
                                   By default the builder adds a ``AuthorizationHeaderInterceptor`` and ``AuthorizingInterceptor`` that add any existing
                                   access tokens from the TokenStorage as Authorization header and try requesting a valid access token when a 401 error code is found, respectively.
     */
    public static func create(
        baseUrl: String,
        client: Client,
        currentDeviceInfoProvider: CurrentDeviceInfoProvider,
        networkOptionsBuilder: @escaping ((IdentityClient) -> NetworkOptions)) throws -> IdentityClient {
        IdentityClientImpl(
            client: client,
            configuration: try .init(baseUrl: baseUrl),
            currentDeviceInfoProvider: currentDeviceInfoProvider,
            valueStorage: UserDefaults.standard,
            tokenStorage: .ephemeral,
            networkOptionsBuilder: networkOptionsBuilder)
    }
    
}

