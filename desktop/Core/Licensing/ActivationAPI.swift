import Foundation

/// API client for license activation and device management
public actor ActivationAPI {

    public enum ActivationError: Error, LocalizedError {
        case networkError(String)
        case invalidResponse
        case limitReached(String)
        case licenseInvalid(String)
        case serverError(String)

        public var errorDescription: String? {
            switch self {
            case .networkError(let msg):
                return "Network error: \(msg)"
            case .invalidResponse:
                return "Invalid server response"
            case .limitReached(let msg):
                return msg
            case .licenseInvalid(let msg):
                return msg
            case .serverError(let msg):
                return "Server error: \(msg)"
            }
        }
    }

    public struct DeviceInfo: Codable {
        public let deviceId: String
        public let deviceName: String
        public let activatedAt: String
        public let lastSeenAt: String
    }

    public struct ActivationResponse: Codable {
        public let valid: Bool
        public let payload: LicensePayload?
        public let activations: ActivationInfo?
        public let error: String?
    }

    public struct ActivationInfo: Codable {
        public let count: Int
        public let limit: Int
        public let devices: [DeviceInfo]
    }

    private let baseURL: String

    public init(baseURL: String = "https://maccleanerpro.com") {
        self.baseURL = baseURL
    }

    /// Verify license without device activation
    public func verifyLicense(_ licenseKey: String) async throws -> ActivationResponse {
        let request = VerifyRequest(
            licenseKey: licenseKey,
            action: "verify"
        )

        return try await makeRequest(request)
    }

    /// Activate license on this device
    public func activateLicense(
        _ licenseKey: String,
        deviceId: String,
        deviceName: String
    ) async throws -> ActivationResponse {
        let request = VerifyRequest(
            licenseKey: licenseKey,
            deviceId: deviceId,
            deviceName: deviceName,
            action: "activate"
        )

        let response = try await makeRequest(request)

        // Check for limit reached error
        if !response.valid, let error = response.error, error.contains("limit reached") {
            throw ActivationError.limitReached(error)
        }

        if !response.valid, let error = response.error {
            throw ActivationError.licenseInvalid(error)
        }

        return response
    }

    /// Deactivate license on a specific device
    public func deactivateLicense(
        _ licenseKey: String,
        deviceId: String
    ) async throws -> ActivationResponse {
        let request = VerifyRequest(
            licenseKey: licenseKey,
            deviceId: deviceId,
            action: "deactivate"
        )

        return try await makeRequest(request)
    }

    // MARK: - Private

    private struct VerifyRequest: Codable {
        let licenseKey: String
        let deviceId: String?
        let deviceName: String?
        let action: String

        init(licenseKey: String, deviceId: String? = nil, deviceName: String? = nil, action: String) {
            self.licenseKey = licenseKey
            self.deviceId = deviceId
            self.deviceName = deviceName
            self.action = action
        }
    }

    private func makeRequest(_ request: VerifyRequest) async throws -> ActivationResponse {
        let url = URL(string: "\(baseURL)/.netlify/functions/license-verify")!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ActivationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ActivationError.serverError("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ActivationResponse.self, from: data)
    }
}
