//
//  IdentityClientDeviceManagement.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation
import Combine


private struct AuthRegistrationContext: Codable {
    typealias Context = QuickLoginStatus.Context
    
    let deviceId: String
    let context: Context
    
    private init(deviceId: String, context: Context) {
        self.deviceId = deviceId
        self.context = context
    }
    
    @discardableResult
    static func clear(_ context: Context, on storage: SecureStorage) -> Bool {
        storage.remove(key: context.storageKey)
    }
    
    @discardableResult
    static func store(
        deviceId: String,
        context: Context,
        on storage: SecureStorage
    ) -> Bool {
        let item = Self(deviceId: deviceId, context: context)
        let data = try? JSONEncoder().encode(item)
        
        guard let data else { return false }
        
        storage.store(key: context.storageKey, data: data)
        
        return true
    }
}

public extension ValueStorageKey {
    static let deviceAuthContextFingerprint: ValueStorageKey = "device_auth_context_fingerprint"
    static let deviceAuthContextDevicePin  : ValueStorageKey = "device_auth_context_devicePin"
}

public class DevicesData: ObservableObject, @unchecked Sendable {
    @Published
    public private(set)
    var userDevices: [DeviceInfo]? = nil
    
    @Published
    public private(set)
    var thisDevice: DeviceInfo? = nil
    
    func updateWith(userDevices: [DeviceInfo]?, thisDeviceId: String?) {
        self.userDevices = userDevices
        self.thisDevice = userDevices?.first(where: {
            $0.deviceId == thisDeviceId
        })
    }
}



final public class QuickLoginStatus: ObservableObject, @unchecked Sendable {
    
    public enum Context: String, Codable {
        case devicePin, fingerprint
        
        internal var storageKey: ValueStorageKey {
            switch self {
            case .devicePin  : .deviceAuthContextDevicePin
            case .fingerprint: .deviceAuthContextFingerprint
            }
        }
    }
    
    let storage: SecureStorage
    
    init(storage: SecureStorage) {
        self.storage = storage
    }
    
    @Published
    internal
    var thisDevice: DeviceInfo? = nil
    
    public var hasDevicePin: Bool {
        thisDevice?.supportsPinLogin ?? false
    }
    
    public var hasFingerprint: Bool {
        thisDevice?.supportsFingerprintLogin ?? false
    }
    
    public var hasQuickLogin: Bool {
        hasFingerprint || hasDevicePin
    }
    
    public func hasRegistered(for context: Context) -> Bool {
        storage.read(key: context.storageKey).map { data in
            (try? JSONDecoder().decode(
                AuthRegistrationContext.self,
                from: data))?
                    .context == context
        } ?? false
    }
}

/// Manages the users devices. Provides info as bindable objects that the relevant UI can use.
final public actor DevicesService: Sendable {

    nonisolated
    public let devicesInfo: DevicesData = .init()
    
    nonisolated
    public let quickLoginStatus: QuickLoginStatus
    
    private let identityOptions      : IdentityClientOptions
    private let serviceProvider      : ServiceHub
    private let thisDeviceRepository : ThisDeviceRepository
    private let devicesRepository    : DevicesRepository
    private let valueStorage         : ValueStorage
    private let secureStorage        : SecureStorage
    private let client               : Client

    
    private var cancellables         = Set<AnyCancellable>()
    
    public var ids: ThisDeviceIds {
        thisDeviceRepository.ids
    }
    
    init(identityOptions: IdentityClientOptions,
         serviceProvider: ServiceHub,
         thisDeviceRepository: ThisDeviceRepository,
         devicesRepository: DevicesRepository,
         valueStorage: ValueStorage,
         secureStorage: SecureStorage,
         client: Client) {
        
        self.identityOptions = identityOptions
        self.serviceProvider = serviceProvider
        self.thisDeviceRepository = thisDeviceRepository
        self.devicesRepository = devicesRepository
        self.valueStorage = valueStorage
        self.secureStorage = secureStorage
        self.client = client
        self.quickLoginStatus = .init(storage: secureStorage)

        self.devicesInfo
            .$thisDevice
            .assign(to: \.thisDevice, on: quickLoginStatus)
            .store(in: &cancellables)
    }

    /// Refresh the list of the user's devices
    public func refreshDevices() async throws {
        try await updateFetchDeviceList()
    }
    
    
    /// Register or update an existing registration of the current device.
    @discardableResult
    public func updateThisDeviceRegistration(pnsHandle: String? = nil, tags: [String]? = nil) async throws -> DeviceInfo {
        let isRegistered: Bool = try await {
            if devicesInfo.thisDevice == nil {
                try await updateFetchDeviceList()
                return devicesInfo.thisDevice != nil
            } else { return true }
        }()
        
        if isRegistered {
            let ids = thisDeviceRepository.ids
            try await devicesRepository.update(deviceId: ids.device,
                                              with: .from(service: thisDeviceRepository,
                                                          pnsHandle: pnsHandle,
                                                          customTags: tags))
        } else {
            thisDeviceRepository.resetIds()
            try await devicesRepository.create(device: .from(service: thisDeviceRepository,
                                                            pnsHandle: pnsHandle,
                                                            customTags: tags))
        }
        
        try await updateFetchDeviceList()
        
        return devicesInfo.thisDevice!
    }
    
    /// Delete a devices from the user's registered devices list.
    public func delete(deviceId: String) async throws {
        try await devicesRepository.delete(deviceId: deviceId)
        
        devicesInfo.updateWith(
            userDevices: devicesInfo
                .userDevices?
                .filter { $0.deviceId == deviceId },
            thisDeviceId: thisDeviceRepository.ids.device)
    }

    
}


// MARK: - Authorize device


extension DevicesService {
    
    
    
    /// Register or update a device, to be able to perform a **device\_authentication** grant with **pin** mode
    /// This method returns a **lambda** that, provided with on otp, completes the device pin registration.
    /// ```swift
    ///
    /// let pin: String = /* receive pin */
    /// let continuation = try await registerDevice(withPin: pin)
    ///
    /// let otpValue = /* receive otp */
    /// try await continuation(.submit(value: otpValue)
    ///
    /// ```
    /// It is not necessary to call the continuation with an OtpResult.aborted result but it is recommended.
     
    public func registerDevice(withPin pin: String, otpChannel: TotpDeliveryChannel? = nil) async throws -> @Sendable (CallbackType.OtpResult) async throws -> () {
        do {
            _ = CryptoUtils.deleteKeyPair(locked: false, tagged: .devicePin)
            let keys = try CryptoUtils.createKeyPair(locked: false, tagged: .devicePin)
            
            let verifier     = CryptoRandom.uniqueId()
            let verifierHash = CryptoUtils.challenge(for: verifier)
            let deviceIds    = thisDeviceRepository.ids
            let deviceInfo   = thisDeviceRepository.info
            let devicePin    = try CryptoUtils.prepare(pin: pin, withDeviceId: deviceIds.device, and: keys)
            
            
            /* TODO: This request generally has an OTP side-effect, except if the user has the otp_authenticated=true claim.
             Find a nice way to decide if it will and pass it to the OTP provider?
             */
            let response = try await devicesRepository.initialize(authRequest: .pinInit(codeChallenge: verifierHash,
                                                                                       deviceIds: deviceIds,
                                                                                       client: client))
            
            let signedVerifier = try CryptoUtils.sign(string: response.challenge, with: keys)
            
            return { [weak self] otpResult in
                guard let self = self else { return }
                
                
                let securityDataHolder = self.serviceProvider.authorizationService
                
                do {
                    let registration = try await devicesRepository.complete(registrationRequest: .pin(code: response.challenge,
                                                                                                     codeVerifier: verifier,
                                                                                                     codeSignature: signedVerifier,
                                                                                                     deviceIds: deviceIds,
                                                                                                     deviceInfo: deviceInfo,
                                                                                                     devicePin: devicePin,
                                                                                                     otp: otpResult.otpValue))
                    
                    try await self.updateDeviceWith(deviceId: deviceIds.device)
                    
                    self.thisDeviceRepository.update(
                        registrationId: registration.registrationId)
                    
                    await securityDataHolder.updateSecurityData(.init(key: keys.private))
                    
                    AuthRegistrationContext.store(
                        deviceId: deviceIds.device,
                        context: .devicePin,
                        on: self.secureStorage)
                } catch {
                    await securityDataHolder.updateSecurityData(nil)
                    AuthRegistrationContext.clear(.devicePin, on: secureStorage)
                    throw error
                }
            }
        } catch {
            AuthRegistrationContext.clear(.devicePin, on: secureStorage)
            throw error
        }
    }
    
    
    /// Register or update a device, to be able to perform a **device\_authentication** grant with **fingerprint** mode
    /// This method returns a **lambda** that, provided with on otp, completes the device fingerprint registration.
    /// ```swift
    ///
    /// let continuation = try await registerDeviceFingerprint()
    ///
    /// let otpValue = /* receive otp */
    /// try await continuation(.submit(value: otpValue)
    /// ```
    /// It is not necessary to call the continuation with an OtpResult.aborted result but it is recommended.
    public func registerDeviceFingerprint(otpChannel: TotpDeliveryChannel? = nil) async throws -> @Sendable (CallbackType.OtpResult) async throws -> () {
        do {
            _ = CryptoUtils.deleteKeyPair(locked: true, tagged: .fingerprint)
            let keys = try CryptoUtils.createKeyPair(locked: true, tagged: .fingerprint)
            
            let verifier     = CryptoRandom.uniqueId()
            let verifierHash = CryptoUtils.challenge(for: verifier)
            let deviceIds    = thisDeviceRepository.ids
            let deviceInfo   = thisDeviceRepository.info
            let devicePem    = try CryptoUtils.pem(for: keys)
            
            /* TODO: This request could have an OTP side-effect.
             Find a nice way to decide if it will and pass it to the OTP provider?
             */
            
            let response = try await devicesRepository.initialize(authRequest: .biometrictInit(codeChallenge: verifierHash,
                                                                                              deviceIds: deviceIds,
                                                                                              client: client))
            let signedVerifier = try CryptoUtils.sign(string: response.challenge, with: keys)

            return { [weak self] otpResult in
                guard let self = self else { return }
                do {
                    let registration = try await self.devicesRepository.complete(
                        registrationRequest: .biometric(
                            code: response.challenge,
                            codeVerifier: verifier,
                            codeSignature: signedVerifier,
                            deviceIds: deviceIds,
                            deviceInfo: deviceInfo,
                            publicPem: devicePem,
                            otp: otpResult.otpValue))
                    
                    try await self.updateDeviceWith(deviceId: deviceIds.device)
                    
                    
                    self.thisDeviceRepository.update(registrationId: registration.registrationId)
                    // await self.quickLoginStatus.update(hasFingerprint: true)
                    AuthRegistrationContext.store(
                        deviceId: deviceIds.device,
                        context: .fingerprint,
                        on: self.secureStorage)
                    
                } catch {
                    AuthRegistrationContext.clear(.fingerprint, on: secureStorage)
                    throw error
                }
            }
        } catch {
            AuthRegistrationContext.clear(.fingerprint, on: secureStorage)
            throw error
        }
    }
    
    
    /// Remove a device pin registration
    public func removeRegistrationDevicePin() async {
        CryptoUtils.deleteKeyPair(locked: false, tagged: .devicePin)
        // await quickLoginStatus.update(hasDevicePin: false)
    }
 
    /// Remove a fingerprint registration
    public func removeRegistrationFingerprint() async {
        CryptoUtils.deleteKeyPair(locked: true, tagged: .fingerprint)
        // await quickLoginStatus.update(hasFingerprint: false)
    }
 
    /// Trigger enable current device's trust status
    public func enableDeviceTrust(deviceSelection: CallbackType.DeviceSelection) async throws {
        let ids = thisDeviceRepository.ids
        
        if devicesInfo.userDevices == nil {
            try await refreshDevices()
        }
        
        let devices = (devicesInfo.userDevices ?? []).filter {
            $0.deviceId != ids.device
        }
            
        let currentTrustedCount = devices.count {
            $0.isTrusted == true
        }
        
        let swapDeviceId: String? = await {
            if currentTrustedCount >= identityOptions.maxTrustedDevicesCount {
                switch await deviceSelection(devices) {
                case .swap(let deviceInfo):
                    return deviceInfo.deviceId
                case .aborted:
                    // TODO: this should throw something here?
                    return nil
                }
            }
            
            return nil
        }()
        
        try await devicesRepository.trust(
            deviceId: ids.device,
            bySwappingWith: swapDeviceId)
        
        try await updateDeviceWith(deviceId: ids.device)
        
        if let swapDeviceId { try await updateDeviceWith(deviceId: swapDeviceId) }
    }
    
    /// Remove current device's trust status
    public func removeDeviceTrust() async throws {
        let deviceId = thisDeviceRepository.ids.device
        
        try await devicesRepository.unTrust(deviceId: deviceId)
        try await updateDeviceWith(deviceId: deviceId)
    }
    
}


// MARK: Private helpers

extension DevicesService {
    func updateFetchDeviceList() async throws {
        devicesInfo.updateWith(
            userDevices: try await devicesRepository
                .devices()
                .items,
            thisDeviceId: thisDeviceRepository
                .ids
                .device)
    }

    func updateDeviceWith(deviceId: String) async throws {
        let newDevice = try await devicesRepository.device(byId: deviceId)
        var deviceList = devicesInfo.userDevices ?? []
        let devIndex  = devicesInfo.userDevices?.firstIndex(where: {
            $0.deviceId == newDevice.deviceId
        })
        
        if let index = devIndex {
            deviceList[index] = newDevice
        } else {
            // Prepend the updated device.
            deviceList.insert(newDevice, at: 0)
        }

        devicesInfo.updateWith(
            userDevices: deviceList,
            thisDeviceId: thisDeviceRepository
                .ids
                .device)
    }
}
