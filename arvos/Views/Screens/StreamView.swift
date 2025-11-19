//
//  StreamView.swift
//  arvos
//
//  Professional streaming tool UI - Bento Box Design
//

import SwiftUI

struct StreamView: View {
    @EnvironmentObject var viewModel: StreamingViewModel
    @State private var scannedQRCode: String?

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Main Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if viewModel.isStreaming {
                        streamingBentoGrid
                    } else {
                        idleBentoGrid
                    }
                }
                .padding(16)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !viewModel.isStreaming {
                    // QR Scanner
                    Button {
                        viewModel.showingQRScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .accessibilityLabel("Scan QR Code")
                }
            }
        }
        // Foxglove-style: No ConnectionSheet needed - iPhone is the server!
        // ConnectionSheet removed - we don't connect TO servers, we ARE the server
        .sheet(isPresented: $viewModel.showingQRScanner) {
            QRScannerView(scannedCode: $scannedQRCode)
        }
        .onChange(of: scannedQRCode) { newValue in
            if let code = newValue {
                if self.validateQRCode(code) {
                    viewModel.scanQRCode(code)
                } else {
                    viewModel.showError(message: "Invalid QR code format. Expected ws:// or wss:// URL.")
                }
                scannedQRCode = nil
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Idle State Bento Grid

    private var idleBentoGrid: some View {
        VStack(spacing: 12) {
            // Row 1: Status + Connection
            HStack(spacing: 12) {
                // Status Card
                BentoCard {
                    VStack(spacing: 8) {
                        Text("ARVOS")
                            .font(.system(size: 20, weight: .bold))

                        HStack(spacing: 4) {
                            Circle()
                                .fill(NetworkManager.shared.connectedClients > 0 ? Theme.success : Color.secondary.opacity(0.3))
                                .frame(width: 6, height: 6)
                            Text("\(NetworkManager.shared.connectedClients)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Mode Card
                BentoCard {
                    VStack(spacing: 4) {
                        Image(systemName: viewModel.selectedMode.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                        Text(viewModel.selectedMode.rawValue.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 80)

            // Row 2: Mode Selector
            BentoCard {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(StreamMode.allCases) { mode in
                            ModeChip(
                                mode: mode,
                                isSelected: viewModel.selectedMode == mode,
                                action: { viewModel.selectMode(mode) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 60)

            // Row 3: Custom Sensors (if custom mode)
            if viewModel.selectedMode == .custom {
                BentoCard {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        SensorChip(icon: "camera.fill", label: "Cam", isEnabled: viewModel.customCameraEnabled) {
                            viewModel.toggleCustomCamera()
                        }
                        SensorChip(icon: "cube.fill", label: "Depth", isEnabled: viewModel.customDepthEnabled) {
                            viewModel.toggleCustomDepth()
                        }
                        SensorChip(icon: "gyroscope", label: "IMU", isEnabled: viewModel.customIMUEnabled) {
                            viewModel.toggleCustomIMU()
                        }
                        SensorChip(icon: "location.fill", label: "Pose", isEnabled: viewModel.customPoseEnabled) {
                            viewModel.toggleCustomPose()
                        }
                        SensorChip(icon: "map.fill", label: "GPS", isEnabled: viewModel.customGPSEnabled) {
                            viewModel.toggleCustomGPS()
                        }
                    }
                }
            }

            // Row 4: Server Status
            if NetworkManager.shared.isServerMode {
                BentoCard {
                    ServerStatusView(
                        ipAddresses: NetworkManager.shared.serverIPAddresses,
                        connectedClients: NetworkManager.shared.connectedClients
                    )
                }
            }

            // Row 5: Start Button
            Button {
                viewModel.toggleStreaming()
            } label: {
                Text("Start")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.accent)
                    )
            }
        }
    }

    // MARK: - Streaming State Bento Grid

    private var streamingBentoGrid: some View {
        VStack(spacing: 12) {
            // Row 1: Live Status
            HStack(spacing: 12) {
                // Live Indicator
                BentoCard {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.recording)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.system(.caption, weight: .bold))
                            .foregroundColor(Theme.recording)
                    }
                }
                .frame(maxWidth: .infinity)

                // FPS
                BentoCard {
                    VStack(spacing: 2) {
                        Text(viewModel.fpsFormatted)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                        Text("FPS")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Recording Time
                if viewModel.recordingDuration > 0 {
                    BentoCard {
                        VStack(spacing: 2) {
                            Text(viewModel.recordingDurationFormatted)
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .bold,
                                        design: .monospaced
                                    )
                                )
                                .foregroundColor(Theme.recording)
                            Text("REC")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70)

            // Row 2: Active Sensors
            BentoCard {
                HStack(spacing: 8) {
                    if viewModel.sensorStatuses.camera == .active {
                        ActiveSensorBadge(icon: "camera.fill")
                    }
                    if viewModel.sensorStatuses.depth == .active {
                        ActiveSensorBadge(icon: "cube.fill")
                    }
                    if viewModel.sensorStatuses.imu == .active {
                        ActiveSensorBadge(icon: "gyroscope")
                    }
                    if viewModel.sensorStatuses.pose == .active {
                        ActiveSensorBadge(icon: "location.fill")
                    }
                    if viewModel.sensorStatuses.gps == .active {
                        ActiveSensorBadge(icon: "map.fill")
                    }
                    Spacer()
                }
            }
            .frame(height: 50)

            // Row 3: Server Status
            if NetworkManager.shared.isServerMode {
                BentoCard {
                    ServerStatusView(
                        ipAddresses: NetworkManager.shared.serverIPAddresses,
                        connectedClients: NetworkManager.shared.connectedClients
                    )
                }
            }

            Spacer(minLength: 20)

            // Row 4: Stop Button
            Button {
                viewModel.toggleStreaming()
            } label: {
                Text("Stop")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.recording)
                    )
            }
        }
    }
}

// MARK: - Bento Components

struct BentoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
    }
}

struct ModeChip: View {
    let mode: StreamMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 12))
                Text(mode.rawValue)
                    .font(.system(.caption2, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Theme.accent : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

struct SensorChip: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isEnabled ? .white : .secondary)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isEnabled ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? Theme.accent : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActiveSensorBadge: View {
    let icon: String

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.accent)
            )
    }
}


// MARK: - QR Code Validation Extension

extension StreamView {
    private func validateQRCode(_ code: String) -> Bool {
        // Must be a valid URL
        guard let url = URL(string: code) else {
            return false
        }

        // Must have ws:// or wss:// scheme
        guard let scheme = url.scheme, (scheme == "ws" || scheme == "wss") else {
            return false
        }

        // Must have a host
        guard let host = url.host, !host.isEmpty else {
            return false
        }

        // Port must be valid if specified
        if let port = url.port {
            guard (1...65535).contains(port) else {
                return false
            }
        }

        return true
    }
}

// Removed IMUSensorCard, DepthSensorCard, PoseSensorCard to improve performance

#Preview {
    StreamView()
        .environmentObject(StreamingViewModel())
}
