//
//  IdentityClientDeviceManagement.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation
import Combine


fileprivate extension ValueStorageKey {
    static var devicePinKey   = ValueStorageKey(name: "device_registration_device_pin" )
    static var fingerprintKey = ValueStorageKey(name: "device_registration_fingerprint")
}

public class DevicesData {
    @Published
    public internal(set)
    var userDevices: [DeviceInfo]? = nil
    
    @Published
    public internal(set)
    var thisDevice: DeviceInfo? = nil
}



public class QuickLoginStatus: ObservableObject {
    
    @Published
    public internal(set)
    var hasDevicePin: Bool = false
    
    @Published
    public internal(set)
    var hasFingerprint: Bool = false
    
    @Published
    public internal(set)
    var hasQuickLogin: Bool = false

}


/**
 Manages the users devices. Provides info as bindable objects that the relevant UI can use.
 */
public protocol DevicesService: AnyObject {
    
    var devicesInfo: DevicesData { get }
    
    var quickLoginStatus: QuickLoginStatus { get }
    
    
    func refreshDevices() async throws
    
    /** Register or update an existing registration of the current device. */
    func updateThisDeviceRegistration(pnsHandle: String?, tags: [String]?) async throws
    
    /** Delete a devices from the user's registered devices list. */
    func delete(deviceId: String) async throws

    
    /**
     Register or update a device, to be able to perform a **device\_authentication** grant with **pin** mode
     This method returns a **lambda** that, provided with on otp, completes the device pin registration.
     ```
     
     let pin: String = makePin()
     let continuation = try await registerDevice(withPin: pin)
     
     // If success show otp input
     try await continuation(otpResult)
     
     ```
     It is not necessary to call the continuation with an OtpResult.aborted result but it is recommended.
     */
    func registerDevice(withPin pin: String) async throws -> (CallbackType.OtpResult) async throws -> ()
    
    /**
     Register or update a device, to be able to perform a **device\_authentication** grant with **pin** mode
     This method returns a **lambda** that, provided with on otp, completes the device pin registration.
     ```
     
     let pin: String = makePin()
     let continuation = try await registerDevice(withPin: pin)
     
     // If success show otp input
     try await continuation(otpResult)
     
     ```
     It is not necessary to call the continuation with an OtpResult.aborted result but it is recommended.
     */
    func registerDevice(withPin pin: String, otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> ()

    
    /**
     Register or update a device, to be able to perform a **device\_authentication** grant with **fingerprint** mode
     This method returns a **lambda** that, provided with on otp, completes the device fingerprint registration.
     ```
     
     let continuation = try await registerDeviceFingerprint()
     // If success show otp input
     try await continuation(otpResult)
     
     ```
     It is not necessary to call the continuation with an OtpResult.aborted result but it is recommended.
     */
    func registerDeviceFingerprint() async throws -> (CallbackType.OtpResult) async throws -> ()

    
    /**
     Register or update a device, to be able to perform a **device\_authentication** grant with **fingerprint** mode
     This method returns a **lambda** that, provided with on otp, completes the device fingerprint registration.
     ```
     
     let continuation = try await registerDeviceFingerprint()
     // If success show otp input
     try await continuation(otpResult)
     
     ```
     It is not necessary to call the continuation with an OtpResult.aborted result but it is recommended.
     */
    func registerDeviceFingerprint(otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> ()
    
    /** Remove a device pin registration */
    func removeRegistrationDevicePin() async
    
    /** Remove a fingerprint registration */
    func removeRegistrationFingerprint() async
    
    /** Trigger enable current device's trust status */
    func enableDeviceTrust(deviceSelection: CallbackType.DeviceSelection) async throws
    
    /** Remove current device's trust status */
    func removeDeviceTrust() async throws
    
}


internal class DevicesServiceImpl: DevicesService {

    public let devicesInfo: DevicesData = .init()
    
    public let quickLoginStatus: QuickLoginStatus = .init()
    
    private let identityOptions      : IdentityClientOptions
    private let thisDeviceRepository : ThisDeviceRepository
    private let devicesRepository    : DevicesRepository
    private let valueStorage         : ValueStorage
    private let client               : Client

    private var cancellables         = Set<AnyCancellable>()
    
    init(identityOptions: IdentityClientOptions,
         thisDeviceRepository: ThisDeviceRepository,
         devicesRepository: DevicesRepository,
         valueStorage: ValueStorage,
         client: Client) {
        
        self.identityOptions = identityOptions
        self.thisDeviceRepository = thisDeviceRepository
        self.devicesRepository = devicesRepository
        self.valueStorage = valueStorage
        self.client = client
        
        self.devicesInfo.$userDevices
            .sink { [weak self] devices in
                guard let self = self else { return }
                let deviceId = self.thisDeviceRepository
                    .ids
                    .device
                
                self.devicesInfo.thisDevice = devices?.first(where: {
                    $0.deviceId == deviceId
                })
            }
            .store(in: &cancellables)
        
        
        self.quickLoginStatus.hasDevicePin   = valueStorage.readBool(forKey: .devicePinKey)   ?? false
        self.quickLoginStatus.hasFingerprint = valueStorage.readBool(forKey: .fingerprintKey) ?? false
        
        self.quickLoginStatus
            .$hasFingerprint
            .sink { [weak self] newValue in
                self?.valueStorage.store(value: newValue, forKey: .fingerprintKey)
            }.store(in: &cancellables)
        
        self.quickLoginStatus.$hasDevicePin
            .sink { [weak self] newValue in
                self?.valueStorage.store(value: newValue, forKey: .devicePinKey)
            }.store(in: &cancellables)
        
        self.quickLoginStatus.$hasFingerprint
            .combineLatest(self.quickLoginStatus.$hasDevicePin)
            .map { $0 || $1 }
            .sink(receiveValue: { [weak self] result in
                self?.quickLoginStatus.hasQuickLogin = result
            })
            .store(in: &cancellables)
    }

    
    public func refreshDevices() async throws {
        try await updateFetchDeviceList()
    }
    
    
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
    
    public func delete(deviceId: String) async throws {
        try await devicesRepository.delete(deviceId: deviceId)
        
        devicesInfo.userDevices = devicesInfo.userDevices?.filter {
            $0.deviceId == deviceId
        }
    }

    
}


// MARK: - Authorize device


extension DevicesServiceImpl {
    
    public func registerDevice(withPin pin: String) async throws -> (CallbackType.OtpResult) async throws -> () {
        try await registerDevice(withPin: pin, otpChannel: nil)
    }
    
    public func registerDevice(withPin pin: String, otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> () {
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
                    
                    self.thisDeviceRepository.update(registrationId: registration.registrationId)
                    self.quickLoginStatus.hasDevicePin = true
                } catch {
                    self.quickLoginStatus.hasDevicePin = false
                    throw error
                }
            }
        } catch {
            quickLoginStatus.hasDevicePin = false
            throw error
        }
    }
    
    
    public func registerDeviceFingerprint() async throws -> (CallbackType.OtpResult) async throws -> () {
        try await registerDeviceFingerprint(otpChannel: nil)
    }
    
    public func registerDeviceFingerprint(otpChannel: TotpDeliveryChannel?) async throws -> (CallbackType.OtpResult) async throws -> () {
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
                    
                    self.thisDeviceRepository.update(registrationId: registration.registrationId)
                    self.quickLoginStatus.hasFingerprint = true
                } catch {
                    self.quickLoginStatus.hasFingerprint = false
                    throw error
                }
            }
        } catch {
            quickLoginStatus.hasFingerprint = false
            throw error
        }
    }
    
    
    public func removeRegistrationDevicePin() async {
        CryptoUtils.deleteKeyPair(locked: false, tagged: .devicePin)
        quickLoginStatus.hasDevicePin = false
    }
 
    public func removeRegistrationFingerprint() async {
        CryptoUtils.deleteKeyPair(locked: true, tagged: .fingerprint)
        quickLoginStatus.hasFingerprint = false
    }
 
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
                if case .swap(let deviceInfo) = await deviceSelection(devices) {
                    return deviceInfo.deviceId
                } else {
                    // TODO: this should throw something here?
                    return nil
                }
            }
            
            return nil
        }()
        
        try await devicesRepository.trust(deviceId: ids.device, bySwappingWith: swapDeviceId)
        
        try await updateDeviceWith(deviceId: ids.device)
        
        if let swapDeviceId { try await updateDeviceWith(deviceId: swapDeviceId) }
    }
    
    public func removeDeviceTrust() async throws {
        let deviceId = thisDeviceRepository.ids.device
        
        try await devicesRepository.unTrust(deviceId: deviceId)
        try await updateDeviceWith(deviceId: deviceId)
    }
    
}


// MARK: Private helpers

extension DevicesServiceImpl {
    func updateFetchDeviceList() async throws {
        devicesInfo.userDevices = try await devicesRepository.devices().items
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

        devicesInfo.userDevices = deviceList
    }
}
