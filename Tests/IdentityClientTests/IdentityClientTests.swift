import Combine
import Foundation
import Testing

@testable import IdentityClient

@Suite("UserService")
struct UserServiceTests {

    @MainActor
    @Test("refreshUserInfo publishes the fetched user and updates actor state")
    func refreshUserInfoPublishesFetchedUser() async throws {
        let expectedUser = UserInfo.sample(sub: "user-1", name: "Ada Lovelace")
        let repository = UserInfoRepositorySpy(response: expectedUser)
        let service = UserService(userRepository: repository)
        var receivedSubjects: [String?] = []

        let cancellable = service.user.sink { user in
            receivedSubjects.append(user?.sub)
        }

        let result = try await service.refreshUserInfo()

        #expect(result.sub == "user-1")
        #expect(await service.info?.sub == "user-1")
        #expect(repository.callCount == 1)
        #expect(receivedSubjects == [nil, "user-1"])
        
        _ = cancellable
    }
}

@Suite("DevicesService")
struct DevicesServiceTests {

    @MainActor
    @Test("refreshDevices publishes user devices, current device, and quick login status")
    func refreshDevicesPublishesDeviceSnapshots() async throws {
        let currentDevice = DeviceInfo.sample(
            deviceId: "device-1",
            supportsPinLogin: true,
            supportsFingerprintLogin: false
        )
        let otherDevice = DeviceInfo.sample(deviceId: "device-2")
        let repository = DevicesRepositorySpy(devices: [currentDevice, otherDevice])
        let service = makeDevicesService(devicesRepository: repository)
        var devicesSnapshots: [DevicesData] = []
        var quickLoginSnapshots: [QuickLoginStatus] = []

        let devicesCancellable = service.devicesInfo.sink { snapshot in
            devicesSnapshots.append(snapshot)
        }
        let quickLoginCancellable = service.quickLoginStatus.sink { status in
            quickLoginSnapshots.append(status)
        }

        try await service.refreshDevices()
        let currentDevicesInfo = await service.currentDevicesInfo
        let currentQuickLoginStatus = await service.currentQuickLoginStatus

        #expect(repository.devicesCallCount == 1)
        #expect(currentDevicesInfo.userDevices?.map(\.deviceId) == ["device-1", "device-2"])
        #expect(currentDevicesInfo.thisDevice?.deviceId == "device-1")
        #expect(currentQuickLoginStatus.hasDevicePin)
        #expect(!currentQuickLoginStatus.hasFingerprint)
        #expect(currentQuickLoginStatus.hasQuickLogin)
        #expect(devicesSnapshots.count == 3)
        #expect(devicesSnapshots.last?.thisDevice?.deviceId == "device-1")
        #expect(quickLoginSnapshots.map(\.hasQuickLogin) == [false, true])
        _ = (devicesCancellable, quickLoginCancellable)
    }

    @MainActor
    @Test("delete removes current device from actor state and publisher snapshots")
    func deleteCurrentDeviceUpdatesDeviceSnapshots() async throws {
        let currentDevice = DeviceInfo.sample(deviceId: "device-1", supportsPinLogin: true)
        let otherDevice = DeviceInfo.sample(deviceId: "device-2")
        let repository = DevicesRepositorySpy(devices: [currentDevice, otherDevice])
        let service = makeDevicesService(devicesRepository: repository)

        try await service.refreshDevices()

        var emittedAfterDelete: [DevicesData] = []
        let cancellable = service.devicesInfo.sink { snapshot in
            emittedAfterDelete.append(snapshot)
        }

        try await service.delete(deviceId: "device-1")
        let state = await service.currentDevicesInfo
        let quickLogin = await service.currentQuickLoginStatus

        #expect(repository.deletedDeviceIds == ["device-1"])
        #expect(state.thisDevice == nil)
        #expect(state.userDevices?.map(\.deviceId) == ["device-2"])
        #expect(!quickLogin.hasQuickLogin)
        #expect(emittedAfterDelete.last?.thisDevice == nil)
        #expect(emittedAfterDelete.last?.userDevices?.map(\.deviceId) == ["device-2"])
        _ = cancellable
    }
}

private func makeDevicesService(
    devicesRepository: DevicesRepositorySpy,
    thisDeviceRepository: ThisDeviceRepositorySpy = .init()
) -> DevicesService {
    let authRepository = AuthRepositoryStub()
    let accountRepository = MyAccountRepositoryStub()
    let tokenStorage = TokenStorageSpy()
    let client = Client(
        id: "test-client",
        secret: nil,
        userScope: [.openId, .profile],
        appScope: [.identity],
        urls: nil
    )
    let configuration = IdentityConfig(baseUrl: URL(string: "https://identity.example")!)
    let authorizationService = AuthorizationService(
        authRepository: authRepository,
        accountRepository: accountRepository,
        devicesRepository: devicesRepository,
        thisDeviceRepository: thisDeviceRepository,
        tokenStorage: tokenStorage,
        client: client,
        configuration: configuration
    )

    return DevicesService(
        identityOptions: .init(maxTrustedDevicesCount: 1, userPersistentDeviceId: true),
        authorizationService: authorizationService,
        thisDeviceRepository: thisDeviceRepository,
        devicesRepository: devicesRepository,
        valueStorage: ValueStorageSpy(),
        secureStorage: SecureStorage(service: "IdentityClientTests.\(UUID().uuidString)"),
        errorParser: .init { _ in nil },
        client: client
    )
}

private enum TestError: Error {
    case unimplemented
}

private final class UserInfoRepositorySpy: UserInfoRepository, @unchecked Sendable {
    private(set) var callCount = 0
    var response: UserInfo

    init(response: UserInfo) {
        self.response = response
    }

    func userInfo() async throws -> UserInfo {
        callCount += 1
        return response
    }
}

private final class DevicesRepositorySpy: DevicesRepository, @unchecked Sendable {
    private(set) var devicesCallCount = 0
    private(set) var deletedDeviceIds: [String] = []
    private var storedDevices: [DeviceInfo]

    init(devices: [DeviceInfo]) {
        self.storedDevices = devices
    }

    func authorize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse {
        throw TestError.unimplemented
    }

    func initialize(authRequest: DeviceAuthentication.AuthorizationRequest) async throws -> DeviceAuthentication.ChallengeResponse {
        throw TestError.unimplemented
    }

    func complete(registrationRequest: DeviceAuthentication.RegistrationRequest) async throws -> DeviceAuthentication.RegistrationResult {
        throw TestError.unimplemented
    }

    func devices() async throws -> ResultSet<DeviceInfo> {
        devicesCallCount += 1
        return .init(count: storedDevices.count, items: storedDevices)
    }

    func device(byId deviceId: String) async throws -> DeviceInfo {
        guard let device = storedDevices.first(where: { $0.deviceId == deviceId }) else {
            throw TestError.unimplemented
        }
        return device
    }

    func create(device: CreateDeviceRequest) async throws -> DeviceInfo {
        let deviceInfo = DeviceInfo.sample(deviceId: device.deviceId, name: device.name)
        storedDevices.append(deviceInfo)
        return deviceInfo
    }

    func update(deviceId: String, with: UpdateDeviceRequest) async throws {
        guard let index = storedDevices.firstIndex(where: { $0.deviceId == deviceId }) else {
            throw TestError.unimplemented
        }
        storedDevices[index].name = with.name
    }

    func delete(deviceId: String) async throws {
        deletedDeviceIds.append(deviceId)
        storedDevices.removeAll { $0.deviceId == deviceId }
    }

    func trust(deviceId: String, bySwappingWith: String?) async throws {
        try setTrust(true, for: deviceId)
        if let swappedDeviceId = bySwappingWith {
            try setTrust(false, for: swappedDeviceId)
        }
    }

    func unTrust(deviceId: String) async throws {
        try setTrust(false, for: deviceId)
    }

    private func setTrust(_ isTrusted: Bool, for deviceId: String) throws {
        guard let index = storedDevices.firstIndex(where: { $0.deviceId == deviceId }) else {
            throw TestError.unimplemented
        }
        storedDevices[index].isTrusted = isTrusted
    }
}

private final class ThisDeviceRepositorySpy: ThisDeviceRepository, @unchecked Sendable {
    private(set) var resetIdsCallCount = 0
    private(set) var updatedRegistrationIds: [String?] = []
    var ids: ThisDeviceIds
    let info: ThisDeviceInfo

    init(deviceId: String = "device-1") {
        self.ids = .init(device: deviceId, registration: nil)
        self.info = .init(name: "Test iPhone", model: "iPhone", osVersion: "17.0")
    }

    func resetIds() {
        resetIdsCallCount += 1
        ids = .init(device: "reset-device", registration: nil)
    }

    func update(registrationId: String?) -> Bool {
        updatedRegistrationIds.append(registrationId)
        ids.registration = registrationId
        return true
    }
}

private final class AuthRepositoryStub: AuthRepository, @unchecked Sendable {
    func authorize(grant: OAuth2Grant) async throws -> TokenResponse {
        throw TestError.unimplemented
    }

    func revoke(token: TokenType, withBasicAuth: String) async throws {
        throw TestError.unimplemented
    }
}

private final class MyAccountRepositoryStub: MyAccountRepository, @unchecked Sendable {
    func register(request: RegisterUserRequest) async throws { throw TestError.unimplemented }
    func verify(password: ValidatePasswordRequest) async throws -> CredentialsValidationInfo { throw TestError.unimplemented }
    func verify(username: ValidateUsernameRequest) async throws { throw TestError.unimplemented }
    func forgot(password: ForgotPasswordRequest) async throws { throw TestError.unimplemented }
    func forgot(passwordConfirmation: ForgotPasswordConfirmation) async throws { throw TestError.unimplemented }
    func update(password: UpdatePasswordRequest) async throws { throw TestError.unimplemented }
    func update(email: UpdateEmailRequest) async throws  { throw TestError.unimplemented }
    func update(phone: UpdatePhoneRequest) async throws  { throw TestError.unimplemented }
    func verifyEmail(with: OtpTokenRequest) async throws { throw TestError.unimplemented }
    func verifyPhone(with: OtpTokenRequest) async throws { throw TestError.unimplemented }
}

private actor TokenStorageSpy: TokenStorage {
    private(set) var idToken: String?
    private(set) var refreshToken: TokenType?
    private(set) var accessToken: TokenType?
    private(set) var tokenType: String?

    func parse(_ response: TokenResponse) {
        idToken = response.id_token
        refreshToken = .refreshToken(value: response.refresh_token)
        accessToken = .accessToken(value: response.access_token)
        tokenType = response.token_type
    }

    func clearTokens() {
        idToken = nil
        refreshToken = nil
        accessToken = nil
        tokenType = nil
    }
}

private final class ValueStorageSpy: ValueStorage, @unchecked Sendable {
    private var storage: [String: Any] = [:]

    func store(value: Any, forKey key: ValueStorageKey) {
        storage[key.name] = value
    }

    func readValue(forKey key: ValueStorageKey) -> String? {
        storage[key.name] as? String
    }

    func readBool(forKey key: ValueStorageKey) -> Bool? {
        storage[key.name] as? Bool
    }

    func readObject(forKey key: ValueStorageKey) -> Any? {
        storage[key.name]
    }

    func clearValue(forKey key: ValueStorageKey) {
        storage.removeValue(forKey: key.name)
    }
}

private extension UserInfo {
    static func sample(sub: String, name: String? = nil) -> UserInfo {
        UserInfo(
            sub: sub,
            name: name,
            given_name: nil,
            family_name: nil,
            profile_id: nil,
            otp_channel: nil,
            otp_channel_disabled: nil,
            password_expiration_date: nil,
            password_expiration_policy: nil,
            admin: nil,
            preferred_username: nil,
            email: nil,
            email_verified: nil,
            phone_number: nil,
            phone_number_verified: nil,
            max_devices_count: nil,
            password_expired: nil
        )
    }
}

private extension DeviceInfo {
    static func sample(
        deviceId: String,
        name: String? = nil,
        supportsPinLogin: Bool? = nil,
        supportsFingerprintLogin: Bool? = nil,
        isTrusted: Bool? = nil
    ) -> DeviceInfo {
        DeviceInfo(
            deviceId: deviceId,
            name: name,
            platform: nil,
            isPushNotificationsEnabled: nil,
            supportsPinLogin: supportsPinLogin,
            supportsFingerprintLogin: supportsFingerprintLogin,
            model: nil,
            osVersion: nil,
            data: nil,
            dateCreated: nil,
            lastSignInDate: nil,
            isTrusted: isTrusted,
            trustActivationDate: nil,
            canActivateDeviceTrust: nil,
            clientType: nil
        )
    }
}
