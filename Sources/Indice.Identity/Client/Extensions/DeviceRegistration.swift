//
//  IdentityClientDeviceRegistration.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 30/3/23.
//

import Foundation
import Combine


fileprivate extension ValueStorageKey {
    static var devicePinKey   = ValueStorageKey(name: "device_registration_device_pin" )
    static var fingerprintKey = ValueStorageKey(name: "device_registration_fingerprint")
}



public class IdentityClientDeviceStatus: ObservableObject {
    @Published
    public internal(set)
    var hasDevicePin: Bool = false
    
    @Published
    public internal(set)
    var hasFingerprint: Bool = false
    
    @Published
    public internal(set)
    var hasQuickLogin: Bool = false
    
    private let valueStorage : ValueStorage
    private var cancellables = Set<AnyCancellable>()
    
    init(valueStorage: ValueStorage) {
        self.valueStorage = valueStorage
        
        self.hasDevicePin   = valueStorage.readBool(forKey: .devicePinKey)   ?? false
        self.hasFingerprint = valueStorage.readBool(forKey: .fingerprintKey) ?? false
        
        self.$hasFingerprint
            .sink { [weak self] newValue in
                self?.valueStorage.store(value: newValue, forKey: .fingerprintKey)
            }.store(in: &cancellables)
        
        self.$hasDevicePin
            .sink { [weak self] newValue in
                self?.valueStorage.store(value: newValue, forKey: .devicePinKey)
            }.store(in: &cancellables)
        
        self.$hasFingerprint
            .combineLatest(self.$hasDevicePin)
            .map { $0 || $1 }
            .sink(receiveValue: { [weak self] result in
                self?.hasQuickLogin = result
            })
            .store(in: &cancellables)
    }
}

public protocol IdentityClientDeviceRegistration {
    
    typealias DeviceStatus = IdentityClientDeviceStatus
    
    var deviceStatus: DeviceStatus { get }
    
    /** Register or update a device, to be able to perform a **device\_authentication** grant with **pin** mode */
    func registerDevice(withPin pin: String, otpChannel: TotpDeliveryChannel?, otpProvider: CallbackType.OtpProvider) async throws
    
    /** Register or update a device, to be able to perform a **device\_authentication** grant with **fingerprint** mode */
    func registerDeviceFingerprint(otpChannel: TotpDeliveryChannel?, otpProvider: CallbackType.OtpProvider) async throws
    
    /** Remove a device pin registration */
    func removeRegistrationDevicePin() async
    
    /** Remove a fingerprint registration */
    func removeRegistrationFingerprint() async
    
    /** Trigger enable current device's trust status */
    func enableDeviceTrust(deviceSelection: CallbackType.DeviceSelection) async throws
    
    /** Remove current device's trust status */
    func removeDeviceTrust() async throws
}


extension IdentityClient: IdentityClientDeviceRegistration {
    public typealias DeviceRegistration = IdentityClientDeviceRegistration
    
    public var deviceRegistrationService: DeviceRegistration { self }
    
    public func registerDevice(withPin pin: String, otpChannel: TotpDeliveryChannel? = nil, otpProvider: CallbackType.OtpProvider) async throws {
        do {
            _ = CryptoUtils.deleteKeyPair(locked: false, tagged: .devicePin)
            let keys = try CryptoUtils.createKeyPair(locked: false, tagged: .devicePin)
            
            let verifier     = CryptoRandom.uniqueId()
            let verifierHash = CryptoUtils.challenge(for: verifier)
            let deviceIds    = thisDeviceRepository.ids
            let deviceInfo   = thisDeviceRepository.info
            let devicePin    = try CryptoUtils.prepare(pin: pin, withDeviceId: deviceIds.device, and: keys)
            /* TODO: This request could have an OTP side-effect.
             Find a nice way to decide if it will and pass it to the OTP provider?
             */
            let response = try await deviceRepository.initialize(authRequest: .pinInit(codeChallenge: verifierHash,
                                                                                       deviceIds: deviceIds,
                                                                                       client: client))
            
            let signedVerifier = try CryptoUtils.sign(string: response.challenge, with: keys)
            
            // TODO: pass the status of the otp need.
            let otpResult = await otpProvider(true)
            
            
            // TODO: Handle errors and stuff
            // Should this throw something?
            if otpResult.isAborted { deviceStatus.hasDevicePin = false; return }
            
            let registration = try await deviceRepository.complete(registrationRequest: .pin(code: response.challenge,
                                                                                             codeVerifier: verifier,
                                                                                             codeSignature: signedVerifier,
                                                                                             deviceIds: deviceIds,
                                                                                             deviceInfo: deviceInfo,
                                                                                             devicePin: devicePin,
                                                                                             otp: otpResult.otpValue))
            
            thisDeviceRepository.update(registrationId: registration.registrationId)
        } catch {
            deviceStatus.hasDevicePin = false
            throw error
        }
        
        deviceStatus.hasDevicePin = true
    }
    
    
    public func registerDeviceFingerprint(otpChannel: TotpDeliveryChannel? = nil, otpProvider: (Bool) async -> CallbackType.OtpResult) async throws {
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
            
            let response = try await deviceRepository.initialize(authRequest: .biometrictInit(codeChallenge: verifierHash,
                                                                                              deviceIds: deviceIds,
                                                                                              client: client))
            let signedVerifier = try CryptoUtils.sign(string: response.challenge, with: keys)
            
            // TODO: pass the status of the otp need.
            let otpResult = await otpProvider(true)
            
            
            // TODO: Should this throw something?
            if otpResult.isAborted { deviceStatus.hasFingerprint = false; return }
            
            let registration = try await deviceRepository.complete(registrationRequest: .biometric(code: response.challenge,
                                                                                                   codeVerifier: verifier,
                                                                                                   codeSignature: signedVerifier,
                                                                                                   deviceIds: deviceIds,
                                                                                                   deviceInfo: deviceInfo,
                                                                                                   publicPem: devicePem,
                                                                                                   otp: otpResult.otpValue))
            
            thisDeviceRepository.update(registrationId: registration.registrationId)
        } catch {
            deviceStatus.hasFingerprint = false
            throw error
        }
        deviceStatus.hasFingerprint = true
    }
    
    public func removeRegistrationDevicePin() async {
        CryptoUtils.deleteKeyPair(locked: false, tagged: .devicePin)
        deviceStatus.hasDevicePin = false
    }
 
    public func removeRegistrationFingerprint() async {
        CryptoUtils.deleteKeyPair(locked: true, tagged: .fingerprint)
        deviceStatus.hasFingerprint = false
    }
 
    public func enableDeviceTrust(deviceSelection: CallbackType.DeviceSelection) async throws {
        let ids = thisDeviceRepository.ids
        
        if devicesInfo.userDevices == nil {
            try await deviceManagementService.refreshDevices()
        }
        
        let maxTrustedCount = 1 // TODO: Get from API?
        let devices = (devicesInfo.userDevices ?? []).filter {
            $0.deviceId != ids.device
        }
            
        let currentTrustedCount = devices.filter {
            $0.isTrusted == true
        }.count
        
        let swapDeviceId: String? = await {
            if currentTrustedCount >= maxTrustedCount {
                if case .swap(let deviceInfo) = await deviceSelection(devices) {
                    return deviceInfo.deviceId
                } else {
                    // TODO: this should throw something here?
                    return nil
                }
            }
            
            return nil
        }()
        
        try await deviceRepository.trust(deviceId: ids.device, bySwappingWith: swapDeviceId)
        
        try await updateDeviceWith(deviceId: ids.device)
        
        if let swapDeviceId { try await updateDeviceWith(deviceId: swapDeviceId) }
    }
    
    public func removeDeviceTrust() async throws {
        let deviceId = thisDeviceRepository.ids.device
        
        try await deviceRepository.unTrust(deviceId: deviceId)
        try await updateDeviceWith(deviceId: deviceId)
    }
    
}
