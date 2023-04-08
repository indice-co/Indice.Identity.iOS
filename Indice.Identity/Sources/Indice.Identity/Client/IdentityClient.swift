//
//  IdentityClient.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 7/3/23.
//
import Foundation
import Combine
import IndiceNetworkClient

internal extension CryptoUtils.TagData {
    static var devicePin   : CryptoUtils.TagData { IdentityClient.KeyTags.devicePin   }
    static var fingerprint : CryptoUtils.TagData { IdentityClient.KeyTags.fingerprint }
}


public class IdentityClient {
    
    internal struct KeyTags {
        static let devicePin   = "indice.identity.devicepin.tag".data(using: .utf8)!
        static let fingerprint = "indice.identity.fingerprint.tag".data(using: .utf8)!
    }
    
    public struct Errors {
        private init() {}
        
        public static let AuthUrl     = APIError(description: "Authorization endpoint url is invalid", code: nil)
        public static let TrustDevice = APIError(description: "Trust device registration not present", code: nil)
        public static let TrustSwap   = APIError(description: "Another device has the trusted status", code: nil)
        public static let Params      = APIError(description: "Query parameters are malformed",        code: nil)
        public static let SecKeys     = APIError(description: "SecKeys are not available",             code: nil)
        public static let ServiceUnavailable = APIError(description: "Service unavailable",            code: nil)
    }
    
    internal let client          : Client
    internal let authorization   : Authorization
    internal let tokenStorage    : TokenStorage
    private  let valueStorage    : ValueStorage
    private  let servicesFactory : RepositoryFactory.Type
    
    public var tokens: TokenStorageAccessor { get { tokenStorage } }
    
    public private(set) lazy
    var authRepository: AuthRepository = {
        servicesFactory.authRepository(authorization: authorization,
                                       networkClient: networkClient)
    }()
    
    public private(set) lazy
    var accountRepository: MyAccountRepository = {
        servicesFactory.myAccountRepository(authorization: authorization,
                                            networkClient: networkClient)
    }()
    
    public private(set) lazy
    var deviceRepository: DevicesRepository = {
        servicesFactory.devicesRepository(authorization: authorization,
                                          networkClient: networkClient)
    }()
    
    public private(set) lazy
    var userRepository: UserInfoRepository = {
        servicesFactory.userRepository(authorization: authorization,
                                       networkClient: networkClient)
    }()
    
    public private(set) lazy
    var thisDeviceRepository: ThisDeviceRepository = {
        servicesFactory.thisDeviceRepository(storage: valueStorage)
    }()
    
    public private(set) lazy
    var networkClient: NetworkClient = {
        self.createNetworkClient()
    }()
    
    
    
    // MARK: Conformance to DeviceManagement

    public private(set) lazy
    var devicesInfo: DevicesInfo = {
        DevicesInfo(thisDeviceRepository: self.thisDeviceRepository)
    }()
    
    private var devicesCancellation: AnyCancellable? = nil
    
    // MARK: Conformance to DeviceRegistration

    public private(set) lazy
    var deviceStatus: DeviceStatus = {
        DeviceStatus(valueStorage: valueStorage)
    }()
    
    // MARK: Conformance to UserInformation
    public private(set) lazy
    var user: UserInformation = {
        UserInformation()
    }()
    
    
    // MARK: - Init
    public init(client: Client,
                authorization: Authorization,
                servicesFactory: RepositoryFactory.Type = DefaultRepositoryFactory.self,
                valueStorage: ValueStorage = UserDefaults.standard,
                tokenStorage: TokenStorage = .ephemeral) {
        self.client = client
        self.authorization = authorization
        self.servicesFactory = servicesFactory
        self.valueStorage = valueStorage
        self.tokenStorage = tokenStorage
    }
    
}


// MARK: - Extra initialization steps.

private extension IdentityClient {
    
    // Used in lazy initialization of network client
    func createNetworkClient() -> NetworkClient {
        let interceptors: [InterceptorProtocol] = [
            AuthorizationHeaderInterceptor(tokenAccessor: self.tokens),
            AuthorizingInterceptor(authServiceProvider: { [weak self] in
                return self
            })
        ]
        
        
        return NetworkClient(interceptors: interceptors)
    }
    
}
