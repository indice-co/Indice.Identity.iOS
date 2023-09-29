//
//  IdentityClientDeviceManagement.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/3/23.
//

import Foundation
import Combine

public class DevicesData {
    @Published
    public internal(set)
    var userDevices: [DeviceInfo]? = nil
    
    @Published
    public internal(set)
    var thisDevice: DeviceInfo? = nil
}

/**
 Manages the users devices. Provides info as bindable objects that the relevant UI can use.
 */
public protocol DevicesService: AnyObject {
    
    var devicesInfo: DevicesData { get }
    
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

internal protocol DevicesServiceInternal: DevicesService {
    func updateFetchDeviceList() async throws
    func updateDeviceWith(deviceId: String) async throws
}


internal class DevicesServiceImpl: DevicesService {

    public let devicesInfo: DevicesData = .init()
    
    private let thisDeviceRepository: ThisDeviceRepository
    private let devicesRepository: DevicesRepository
    private var devicesCancellation: AnyCancellable? = nil
    
    init(thisDeviceRepository: ThisDeviceRepository, devicesRepository: DevicesRepository) {
        self.thisDeviceRepository = thisDeviceRepository
        self.devicesRepository = devicesRepository
        
        self.devicesCancellation = self.devicesInfo.$userDevices
            .sink { [weak self] devices in
                guard let self = self else { return }
                let deviceId = self.thisDeviceRepository
                    .ids
                    .device
                
                self.devicesInfo.thisDevice = devices?.first(where: {
                    $0.deviceId == deviceId
                })
            }
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
                throw IdentityClient.Errors.TrustSwap
            }
            
            return nil
        }()
        
        // Trust current device and update any other needed.
        try await devicesRepository.trust(deviceId: currentId, bySwappingWith: idToSwapWith)
        try await updateDeviceWith(deviceId: currentId)
        
        if let idToSwapWith {
            try await updateDeviceWith(deviceId: idToSwapWith)
        }
    }
    
    public func removeCurrentDeviceTrust() async throws {
        let currentId = thisDeviceRepository.ids.device
        
        try await devicesRepository.unTrust(deviceId: currentId)
        try await updateDeviceWith(deviceId: currentId)
    }
 
    public func refreshDevices() async throws {
        try await updateFetchDeviceList()
    }
    
}




// MARK: Private helpers

extension DevicesServiceImpl: DevicesServiceInternal {
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
