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

public struct DevicesData: Sendable {
    public let userDevices: [DeviceInfo]?
    public let thisDevice: DeviceInfo?
    
    public init(userDevices: [DeviceInfo]? = nil, thisDevice: DeviceInfo? = nil) {
        self.userDevices = userDevices
        self.thisDevice = thisDevice
    }
    
    func setting(thisDevice: DeviceInfo?) -> Self {
        var userDevices = self.userDevices
        
        if let thisDevice {
            if let index = userDevices?.firstIndex(where: { $0.deviceId == thisDevice.deviceId }) {
                userDevices?[index] = thisDevice
            }
        } else if let previous = self.thisDevice {
            userDevices?.removeAll { $0.deviceId == previous.deviceId }
        }
        
        return .init(userDevices: userDevices, thisDevice: thisDevice)
    }
    
    func setting(userDevices: [DeviceInfo]?) -> Self {
        .init(userDevices: userDevices, thisDevice: thisDevice)
    }
}

public struct QuickLoginStatus: Sendable {
    public enum Context: String, Codable, Sendable {
        case devicePin, fingerprint
        
        internal var storageKey: ValueStorageKey {
            switch self {
            case .devicePin  : .deviceAuthContextDevicePin
            case .fingerprint: .deviceAuthContextFingerprint
            }
        }
    }
    
    public let thisDevice: DeviceInfo?
    
    public init(thisDevice: DeviceInfo? = nil) {
        self.thisDevice = thisDevice
    }
    
    public var hasDevicePin: Bool {
        thisDevice?.supportsPinLogin ?? false
    }
    
    public var hasFingerprint: Bool {
        thisDevice?.supportsFingerprintLogin ?? false
    }
    
    public var hasQuickLogin: Bool {
        hasFingerprint || hasDevicePin
    }
}

/// Manages the users devices. Provides device snapshots through CurrentValueSubject publishers.
final public actor DevicesService: Sendable {

    @MainActor
    private let devicesInfoInternal = CurrentValueSubject<DevicesData, Never>(.init())
    
    @MainActor
    public var devicesInfo: AnyPublisher<DevicesData, Never> {
        devicesInfoInternal.eraseToAnyPublisher()
    }
    
    @MainActor
    private let quickLoginStatusInternal = CurrentValueSubject<QuickLoginStatus, Never>(.init())
    
    @MainActor
    public var quickLoginStatus: AnyPublisher<QuickLoginStatus, Never> {
        quickLoginStatusInternal.eraseToAnyPublisher()
    }
    
    
    private let identityOptions      : IdentityClientOptions
    private let authorizationService : AuthorizationService
    private let thisDeviceRepository : ThisDeviceRepository
    private let devicesRepository    : DevicesRepository
    private let valueStorage         : ValueStorage
    private let secureStorage        : SecureStorage
    private let errorParser          : ErrorParser
    private let client               : Client
    
    private var devicesState: DevicesData = .init()
    private var quickLoginState: QuickLoginStatus = .init()
    
    public var ids: ThisDeviceIds {
        thisDeviceRepository.ids
    }
    
    public var currentDevicesInfo: DevicesData {
        devicesState
    }
    
    public var currentQuickLoginStatus: QuickLoginStatus {
        quickLoginState
    }
    
    init(
        identityOptions: IdentityClientOptions,
        authorizationService: AuthorizationService,
        thisDeviceRepository: ThisDeviceRepository,
        devicesRepository: DevicesRepository,
        valueStorage: ValueStorage,
        secureStorage: SecureStorage,
        errorParser: ErrorParser,
        client: Client
    ) {
        self.identityOptions = identityOptions
        self.authorizationService = authorizationService
        self.thisDeviceRepository = thisDeviceRepository
        self.devicesRepository = devicesRepository
        self.valueStorage = valueStorage
        self.secureStorage = secureStorage
        self.errorParser = errorParser
        self.client = client
    }

    /// Refresh the list of the user's devices
    public func refreshDevices() async throws {
        let devices = try await fetchUserDevices()
        await updateDevicesInfo(userDevices: devices)
        await updateDevicesInfo(thisDevice: devices.first(where: { $0.deviceId == ids.device }))
    }
    
    public func refreshThisDevice() async throws {
        await updateDevicesInfo(thisDevice: try await fetchCurrentDevice())
    }
    
    /// Register or update an existing registration of the current device.
    @discardableResult
    public func updateThisDeviceRegistration(pnsHandle: String? = nil, tags: [String]? = nil) async throws -> DeviceInfo {
        let isRegistered: Bool = try await {
            if devicesState.thisDevice == nil {
                try await refreshThisDevice()
                return devicesState.thisDevice != nil
            } else { return true }
        }()
        
        let current: DeviceInfo
        if isRegistered {
            let ids = thisDeviceRepository.ids
            try await devicesRepository.update(deviceId: ids.device,
                                               with: .from(service: thisDeviceRepository,
                                                           pnsHandle: pnsHandle,
                                                           customTags: tags))
            
            current = try await devicesRepository.device(byId: ids.device)
        } else {
            if !identityOptions.userPersistentDeviceId {
                thisDeviceRepository.resetIds()
            }
            
            current = try await devicesRepository
                .create(device: .from(service: thisDeviceRepository,
                                      pnsHandle: pnsHandle,
                                      customTags: tags))
        }
        
        await updateDevicesInfo(thisDevice: current)
        
        return current
    }
    
    /// Delete a devices from the user's registered devices list.
    public func delete(deviceId: String) async throws {
        try await devicesRepository.delete(deviceId: deviceId)
        
        if devicesState.thisDevice?.deviceId == deviceId {
            await updateDevicesInfo(thisDevice: nil)
        }
        
        if var devices = devicesState.userDevices,
           let index = devicesState.userDevices?.firstIndex(where: { $0.deviceId == deviceId }) {
            devices.remove(at: index)
            await updateDevicesInfo(userDevices: devices)
        }
    }
    
    public func hasRegistered(for context: QuickLoginStatus.Context) -> Bool {
        secureStorage.read(key: context.storageKey).map { data in
            (try? JSONDecoder().decode(
                AuthRegistrationContext.self,
                from: data))?
                    .context == context
        } ?? false
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
                
                do {
                    let registration = try await devicesRepository.complete(registrationRequest: .pin(code: response.challenge,
                                                                                                     codeVerifier: verifier,
                                                                                                     codeSignature: signedVerifier,
                                                                                                     deviceIds: deviceIds,
                                                                                                     deviceInfo: deviceInfo,
                                                                                                     devicePin: devicePin,
                                                                                                     otp: otpResult.otpValue))
                    
                    try await self.updateDeviceWith(deviceId: deviceIds.device)
                    
                    self.thisDeviceRepository.update(registrationId: registration.registrationId)
                    
                    AuthRegistrationContext.store(
                        deviceId: deviceIds.device,
                        context: .devicePin,
                        on: self.secureStorage)
                } catch {
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
            
            let response = try await devicesRepository.initialize(authRequest: .biometricInit(codeChallenge: verifierHash,
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
                    
                    await self.authorizationService.updateSecurityData(.init(key: keys.private))
                    
                    AuthRegistrationContext.store(
                        deviceId: deviceIds.device,
                        context: .fingerprint,
                        on: self.secureStorage)
                    
                } catch {
                    await self.authorizationService.updateSecurityData(nil)
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
    }
 
    /// Remove a fingerprint registration
    public func removeRegistrationFingerprint() async {
        CryptoUtils.deleteKeyPair(locked: true, tagged: .fingerprint)
    }
 
    /// Trigger enable current device's trust status
    public func enableDeviceTrust(deviceSelection: CallbackType.DeviceSelection) async throws {
        let ids = thisDeviceRepository.ids
        
        if devicesState.userDevices == nil {
            try await refreshDevices()
        }
        
        let devices = (devicesState.userDevices ?? []).filter {
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
    func fetchCurrentDevice() async throws -> DeviceInfo? {
        do {
            return try await devicesRepository.device(byId: ids.device)
        } catch {
            if errorParser.map(error)?.statusCode == 404 {
                return nil
            }
            
            throw error
        }
    }
    
    func fetchUserDevices() async throws -> [DeviceInfo] {
        try await devicesRepository.devices().items ?? []
    }

    func updateDeviceWith(deviceId: String) async throws {
        let newDevice   = try await devicesRepository.device(byId: deviceId)
        var deviceList  = devicesState.userDevices ?? []
        let devIndex    = devicesState.userDevices?
            .firstIndex(where: { $0.deviceId == newDevice.deviceId })
        
        if let index = devIndex {
            deviceList[index] = newDevice
        } else {
            // Prepend the updated device.
            deviceList.insert(newDevice, at: 0)
        }

        if deviceId == ids.device {
            await updateDevicesInfo(thisDevice: newDevice)
        }
        
        await updateDevicesInfo(userDevices: deviceList)
    }
    
    private func updateDevicesInfo(thisDevice: DeviceInfo?) async {
        devicesState = devicesState.setting(thisDevice: thisDevice)
        quickLoginState = .init(thisDevice: thisDevice)
        let devicesState = devicesState
        let quickLoginState = quickLoginState
        
        await MainActor.run {
            devicesInfoInternal.send(devicesState)
            quickLoginStatusInternal.send(quickLoginState)
        }
    }
    
    private func updateDevicesInfo(userDevices: [DeviceInfo]?) async {
        devicesState = devicesState.setting(userDevices: userDevices)
        let devicesState = devicesState
        
        await MainActor.run {
            devicesInfoInternal.send(devicesState)
        }
    }
}
