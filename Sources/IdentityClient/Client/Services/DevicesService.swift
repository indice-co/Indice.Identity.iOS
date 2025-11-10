//
//  IdentityClientDeviceManagement.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation
import Combine


fileprivate extension ValueStorageKey {
    static let devicePinKey   = ValueStorageKey(name: "device_registration_device_pin" )
    static let fingerprintKey = ValueStorageKey(name: "device_registration_fingerprint")
}

public class DevicesData {
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
    
    @Published
    public private(set)
    var hasDevicePin: Bool = false
    
    @Published
    public private(set)
    var hasFingerprint: Bool = false
    
    public var hasQuickLogin: Bool {
        hasFingerprint || hasDevicePin
    }

    internal func update(hasFingerprint value: Bool) {
        self.hasFingerprint = value
    }
    
    internal func update(hasDevicePin value: Bool) {
        self.hasFingerprint = value
    }
    
    internal func update(hasQuickLogin value: Bool) {
        self.hasFingerprint = value
    }
}

/// Manages the users devices. Provides info as bindable objects that the relevant UI can use.
final public actor DevicesService: Sendable {

    public let devicesInfo: DevicesData = .init()
    
    public let quickLoginStatus: QuickLoginStatus = .init()
    
    private let identityOptions      : IdentityClientOptions
    private let serviceProvider      : ServiceHub
    private let thisDeviceRepository : ThisDeviceRepository
    private let devicesRepository    : DevicesRepository
    private let valueStorage         : ValueStorage
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
         client: Client) {
        
        self.identityOptions = identityOptions
        self.serviceProvider = serviceProvider
        self.thisDeviceRepository = thisDeviceRepository
        self.devicesRepository = devicesRepository
        self.valueStorage = valueStorage
        self.client = client
                
        
        self.quickLoginStatus.update(
            hasDevicePin: valueStorage
                .readBool(forKey: .devicePinKey)   ?? false)
        
        self.quickLoginStatus.update(
            hasFingerprint: valueStorage
                .readBool(forKey: .fingerprintKey) ?? false)
  
        
        #warning("well, find a way.")
//        self.quickLoginStatus
//            .$hasFingerprint
//            .sink { [weak self] newValue in
//                self?.valueStorage.store(
//                    value: newValue,
//                    forKey: .fingerprintKey)
//            }.store(in: &cancellables)
//        
//        self.quickLoginStatus.$hasDevicePin
//            .sink { [weak self] newValue in
//                self?.valueStorage.store(
//                    value: newValue,
//                    forKey: .devicePinKey)
//            }.store(in: &cancellables)

    }

    /// Refresh the list of the user's devices
    public func refreshDevices() async throws {
        try await updateFetchDeviceList()
    }
    
    
    /// Register or update an existing registration of the current device.
    public func updateThisDeviceRegistration(pnsHandle: String? = nil, tags: [String]? = nil) async throws {
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
     
    public func registerDevice(withPin pin: String, otpChannel: TotpDeliveryChannel? = nil) async throws -> (CallbackType.OtpResult) async throws -> () {
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
                
                
                let securityDataHolder = await self.serviceProvider.authorizationService()
                
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
                    await self.quickLoginStatus.update(hasDevicePin: true)
                    await securityDataHolder.updateSecurityData(.init(key: keys.private))
                } catch {
                    await securityDataHolder.updateSecurityData(nil)
                    await self.quickLoginStatus.update(hasDevicePin: false)
                    throw error
                }
            }
        } catch {
            await self.quickLoginStatus.update(hasDevicePin: false)
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
    public func registerDeviceFingerprint(otpChannel: TotpDeliveryChannel? = nil) async throws -> (CallbackType.OtpResult) async throws -> () {
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
                    let registration = try await self.devicesRepository.complete(registrationRequest: .biometric(code: response.challenge,
                                                                                                                codeVerifier: verifier,
                                                                                                                codeSignature: signedVerifier,
                                                                                                                deviceIds: deviceIds,
                                                                                                                deviceInfo: deviceInfo,
                                                                                                                publicPem: devicePem,
                                                                                                                otp: otpResult.otpValue))
                    
                    try await self.updateDeviceWith(deviceId: deviceIds.device)
                    
                    
                    self.thisDeviceRepository.update(registrationId: registration.registrationId)
                    await self.quickLoginStatus.update(hasFingerprint: true)
                    
                } catch {
                    await self.quickLoginStatus.update(hasFingerprint: false)
                    throw error
                }
            }
        } catch {
            await self.quickLoginStatus.update(hasFingerprint: false)
            throw error
        }
    }
    
    
    /// Remove a device pin registration
    public func removeRegistrationDevicePin() async {
        CryptoUtils.deleteKeyPair(locked: false, tagged: .devicePin)
        await quickLoginStatus.update(hasDevicePin: false)
    }
 
    /// Remove a fingerprint registration
    public func removeRegistrationFingerprint() async {
        CryptoUtils.deleteKeyPair(locked: true, tagged: .fingerprint)
        await quickLoginStatus.update(hasFingerprint: false)
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
            
        let currentTrustedCount = devices.filter {
            $0.isTrusted == true
        }.count
        
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
