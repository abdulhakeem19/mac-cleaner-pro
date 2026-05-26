import SwiftUI
import Core

/// License activation view for entering and validating license keys
struct LicenseActivationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var licenseKey = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var validationSuccess = false
    @State private var licensePayload: LicensePayload?
    @State private var showValidatingAnimation = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    // Success checkmark (appears on success)
                    if validationSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green.gradient)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Loading animation (during validation)
                        if isValidating {
                            Image(systemName: "key.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.blue.gradient)
                                .scaleEffect(showValidatingAnimation ? 1.1 : 1.0)
                                .opacity(showValidatingAnimation ? 0.6 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                    value: showValidatingAnimation
                                )
                        } else {
                            // Default key icon
                            Image(systemName: "key.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.blue.gradient)
                        }
                    }
                }
                .frame(height: 60)

                Text(validationSuccess ? "License Activated!" : "Activate License")
                    .font(.title.bold())

                Text(isValidating
                     ? "Verifying your license..."
                     : validationSuccess
                     ? "You now have access to all Pro features"
                     : "Enter your license key to unlock all Pro features")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut, value: isValidating)
                    .animation(.easeInOut, value: validationSuccess)
            }

            // License key input
            VStack(alignment: .leading, spacing: 8) {
                Text("License Key")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                TextField("MCP-XXXXXXXXXXXX", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .disabled(isValidating || validationSuccess)
                    .onChange(of: licenseKey) { _ in
                        validationError = nil
                    }

                if let error = validationError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if validationSuccess, let payload = licensePayload {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Valid License", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)

                        Group {
                            Text("Plan: ") + Text(payload.plan.displayName).bold()
                            Text("Email: ") + Text(payload.email).bold()
                            Text("Machines: ") + Text("\(payload.machineLimit)").bold()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                if !validationSuccess {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Activate") {
                        Task {
                            await activateLicense()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(licenseKey.isEmpty || isValidating)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(32)
        .frame(width: 480, height: 420)
    }

    private func activateLicense() async {
        // Start animations
        isValidating = true
        showValidatingAnimation = true
        validationError = nil
        licensePayload = nil

        defer {
            isValidating = false
            showValidatingAnimation = false
        }

        // Trim whitespace
        let trimmed = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add small delay to show loading animation (better UX)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Validate offline first (Ed25519 signature)
        let result = LicenseValidator.validate(trimmed)

        switch result {
        case .valid(let payload):
            // Valid signature - now register with server for machine limits
            do {
                let api = ActivationAPI()
                let deviceID = DeviceIdentifier.getDeviceID()
                let deviceName = DeviceIdentifier.getDeviceName()

                let response = try await api.activateLicense(
                    trimmed,
                    deviceId: deviceID,
                    deviceName: deviceName
                )

                if response.valid {
                    // Activation successful - store locally with full activation data
                    _ = await LicenseManager.shared.setLicenseKey(trimmed, activationInfo: response.activations)
                    licensePayload = payload

                    // Animate success
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        validationSuccess = true
                    }

                    // Auto-dismiss after showing success
                    try? await Task.sleep(for: .seconds(1.5))
                    dismiss()
                } else {
                    validationError = response.error ?? "Activation failed"
                }
            } catch let error as ActivationAPI.ActivationError {
                switch error {
                case .networkError, .invalidResponse:
                    // Connectivity issue — signature already verified locally, activate offline
                    _ = await LicenseManager.shared.setLicenseKey(trimmed)
                    licensePayload = payload
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        validationSuccess = true
                    }
                    try? await Task.sleep(for: .seconds(1.5))
                    dismiss()
                case .limitReached, .licenseInvalid, .serverError:
                    // Definitive server rejection — show the reason
                    validationError = error.localizedDescription
                }
            } catch is CancellationError {
                // Task was cancelled mid-flight — nothing to show
            } catch let urlError as URLError {
                // Network unreachable / timed out — activate offline
                _ = await LicenseManager.shared.setLicenseKey(trimmed)
                licensePayload = payload
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    validationSuccess = true
                }
                try? await Task.sleep(for: .seconds(1.5))
                dismiss()
                _ = urlError  // suppress unused-variable warning
            } catch {
                // DecodingError or any other unexpected failure — don't silently grant Pro
                validationError = "Could not reach the activation server. Check your connection and try again."
            }

        case .invalid(let error):
            validationError = error.localizedDescription
        }
    }
}

#Preview {
    LicenseActivationView()
}
