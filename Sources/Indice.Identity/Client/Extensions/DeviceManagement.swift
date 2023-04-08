//
//  IdentityClientDeviceManagement.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation
import Combine

public class IdentityClientDevicesInfo {
    @Published
    public internal(set)
    var userDevices: [DeviceInfo]? = nil
    
    @Published
    public internal(set)
    var thisDevice: DeviceInfo? = nil
    
    private var devicesCancellation: AnyCancellable? = nil
    private let thisDeviceRepository: ThisDeviceRepository
    
    init(thisDeviceRepository: ThisDeviceRepository) {
        self.thisDeviceRepository = thisDeviceRepository
        
        self.devicesCancellation = self.$userDevices
            .sink { [weak self] devices in
                guard let self = self else { return }
                let deviceId = self.thisDeviceRepository
                    .ids
                    .device
                
                self.thisDevice = devices?.first(where: {
                    $0.deviceId == deviceId
                })
            }
    }
}

public protocol IdentityClientDeviceManagement {
    typealias DevicesInfo = IdentityClientDevicesInfo
    
    var devicesInfo: DevicesInfo { get }
    
    func refreshDevices() async throws
    
    /** Register or update an existing registration of the current device. */
    func updateThisDeviceRegistration(pnsHandle: String?, tags: [String]?) async throws
    
    /** Delete a devices from the user's registered devices list. */
    func delete(deviceId: String) async throws
    
    /** Try and declare the current device as a trusted one. */
    func makeCurrentDeviceTrusted(swapRule: ([DeviceInfo]) async -> DeviceInfo?) async throws
    
    /** Try to remove the trusted status of the current device. */
    func removeCurrentDeviceTrust() async throws
}


extension IdentityClient: IdentityClientDeviceManagement {
    public typealias DeviceManagement = IdentityClientDeviceManagement
    
    public var deviceManagementService: DeviceManagement { self }
    
    public func updateThisDeviceRegistration(pnsHandle: String? = nil, tags: [String]? = nil) async throws {
        let isRegistered: Bool = try await {
            if devicesInfo.thisDevice == nil {
                try await updateFetchDeviceList()
                return devicesInfo.thisDevice != nil
            } else { return true }
        }()
        
        let ids  = thisDeviceRepository.ids
        
        if isRegistered {
            try await deviceRepository.update(deviceId: ids.device,
                                              with: .from(service: thisDeviceRepository,
                                                          pnsHandle: pnsHandle,
                                                          customTags: tags))
        } else {
            try await deviceRepository.create(device: .from(service: thisDeviceRepository,
                                                         pnsHandle: pnsHandle,
                                                         customTags: tags))
        }
        
        try await updateFetchDeviceList()
    }
    
    public func delete(deviceId: String) async throws {
        try await deviceRepository.delete(deviceId: deviceId)
        
        devicesInfo.userDevices = devicesInfo.userDevices?.filter {
            $0.deviceId == deviceId
        }
    }

    public func makeCurrentDeviceTrusted(swapRule: ([DeviceInfo]) async -> DeviceInfo?) async throws {
        // Get max trusted device count
        let maxTrustedCount = 1 // TODO: this should be available from the API.
        let currentId = thisDeviceRepository.ids.device
        let otherTrustedDevices = devicesInfo.userDevices?.filter {
            $0.deviceId != currentId && ($0.isTrusted ?? false)
        }
        
        // Check if max trusted limit is reached and offer an option
        // to swap an already trusted device with the current one.
        let idToSwapWith: String? = try await {
            let otherDevicesCount = otherTrustedDevices?.count ?? 0
            if otherDevicesCount >= maxTrustedCount, let otherTrustedDevices {
                if let device = await swapRule(otherTrustedDevices) {
                    return device.deviceId
                }
                
                // If a swap id needed, but no device is selected,
                // throw an error as the trust cannot be offered.
                throw Errors.TrustSwap
            }
            
            return nil
        }()
        
        // Trust current device and update any other needed.
        try await deviceRepository.trust(deviceId: currentId, bySwappingWith: idToSwapWith)
        try await updateDeviceWith(deviceId: currentId)
        
        if let idToSwapWith {
            try await updateDeviceWith(deviceId: idToSwapWith)
        }
    }
    
    public func removeCurrentDeviceTrust() async throws {
        let currentId = thisDeviceRepository.ids.device
        
        try await deviceRepository.unTrust(deviceId: currentId)
        try await updateDeviceWith(deviceId: currentId)
    }
 
    public func refreshDevices() async throws {
        try await updateFetchDeviceList()
    }
    
}




// MARK: Private helpers

private extension IdentityClient /* IdentityClientDeviceManagement extensions */ {
    func updateFetchDeviceList() async throws {
        devicesInfo.userDevices = try await deviceRepository.devices().items
    }

    func updateDeviceWith(deviceId: String) async throws {
        let newDevice = try await deviceRepository.device(byId: deviceId)
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
