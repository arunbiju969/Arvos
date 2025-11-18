//
//  StreamView.swift
//  arvos
//
//  Professional streaming tool UI
//

import SwiftUI

struct StreamView: View {
    @EnvironmentObject var viewModel: StreamingViewModel
    @State private var showDataSourcePicker = false
    @State private var scannedQRCode: String?

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            let isIPhoneLandscape = isLandscape && !isIPad

            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()

                // Camera Preview (when streaming)
                if viewModel.isStreaming {
                    Color.black
                        .ignoresSafeArea()
                }

                if isIPad && isLandscape {
                    // iPad Landscape: Side-by-side layout
                    HStack(spacing: 0) {
                        // Left side: Status and content
                        VStack(spacing: 0) {
                            topStatusBar
                                .background(Color(.systemBackground))

                            Spacer()

                            if viewModel.isStreaming {
                                liveDataBentoBox
                            } else {
                                centerContent
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        // Right side: Controls
                        VStack(spacing: 16) {
                            if !viewModel.isStreaming {
                                modeSelector
                                    .padding(.horizontal)
                            }

                            Spacer()

                            bottomControls
                                .background(Color(.systemBackground))
                        }
                        .frame(width: geometry.size.width * 0.4)
                    }
                } else if isIPhoneLandscape {
                    // iPhone Landscape: Scrollable horizontal layout
                    ScrollView {
                        HStack(spacing: 0) {
                            // Left side: Status and content
                            VStack(spacing: 12) {
                                topStatusBar
                                    .background(Color(.systemBackground))

                                if viewModel.isStreaming {
                                    liveDataBentoBox
                                } else {
                                    centerContent
                                        .padding(.vertical, 20)
                                }
                            }
                            .frame(width: geometry.size.width * 0.5)

                            // Right side: Controls
                            VStack(spacing: 12) {
                                if !viewModel.isStreaming {
                                    modeSelector
                                        .padding(.horizontal, 16)
                                }

                                Spacer()

                                bottomControls
                                    .background(Color(.systemBackground))
                            }
                            .frame(width: geometry.size.width * 0.5)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                } else {
                    // iPhone Portrait: Scrollable vertical layout
                    ScrollView {
                        VStack(spacing: 0) {
                            // Top Status Bar
                            topStatusBar
                                .background(Color(.systemBackground))

                            // Center Content
                            if viewModel.isStreaming {
                                liveDataBentoBox
                                    .padding(.vertical, 20)
                            } else {
                                centerContent
                                    .padding(.vertical, 40)
                            }

                            if !viewModel.isStreaming {
                                modeSelector
                                    .padding(.horizontal)
                                    .padding(.vertical, 16)
                            }

                            // Bottom Controls
                            bottomControls
                                .background(Color(.systemBackground))
                                .padding(.bottom, 20)
                        }
                        .frame(minWidth: geometry.size.width)
                    }
                }
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

    // MARK: - Top Status Bar

    private var topStatusBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Connection Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)

                    Text(viewModel.isConnected ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(viewModel.isConnected ? "Connected to server" : "Not connected")

                Spacer()
            }

            // Live Metrics (when streaming)
            if viewModel.isStreaming {
                HStack(spacing: 16) {
                    MetricBadge(label: "FPS", value: viewModel.fpsFormatted)

                    if viewModel.recordingDuration > 0 {
                        MetricBadge(label: "REC", value: viewModel.recordingDurationFormatted)
                    }
                }
            }

            // Active Sensors
            if viewModel.isStreaming {
                sensorStatusRow
            }
        }
        .padding()
    }

    // MARK: - Sensor Status Row

    private var sensorStatusRow: some View {
        HStack(spacing: 8) {
            if viewModel.sensorStatuses.camera == .active {
                SensorBadge(icon: "camera.fill", label: "CAM")
            }
            if viewModel.sensorStatuses.depth == .active {
                SensorBadge(icon: "cube.fill", label: "DEPTH")
            }
            if viewModel.sensorStatuses.imu == .active {
                SensorBadge(icon: "gyroscope", label: "IMU")
            }
            if viewModel.sensorStatuses.pose == .active {
                SensorBadge(icon: "location.fill", label: "POSE")
            }
            if viewModel.sensorStatuses.gps == .active {
                SensorBadge(icon: "map.fill", label: "GPS")
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Foxglove-Style: No "Connect to Server" needed - iPhone IS the server!
            // Just show the Start/Stop Streaming button

            // Start/Stop Button (Foxglove-style: no connection needed, iPhone is the server!)
            Button {
                viewModel.toggleStreaming()
            } label: {
                Text(viewModel.isStreaming ? "Stop Streaming" : "Start Streaming")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(PrimaryButtonStyle(isDestructive: viewModel.isStreaming))
        }
        .padding()
    }

    // MARK: - Live Data Display (Simplified for Performance)

    private var liveDataBentoBox: some View {
        VStack(spacing: 20) {
            // Live Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(0.5)
                            .scaleEffect(2)
                            .blur(radius: 4)
                    )

                Text("STREAMING")
                    .font(.system(.caption).weight(.semibold))
                    .foregroundColor(.secondary)
                    .tracking(1)
            }

            // Stats Grid - Clean and minimal
            HStack(spacing: 16) {
                StreamingStat(label: "FPS", value: viewModel.fpsFormatted)
                StreamingStat(label: "Mode", value: viewModel.selectedMode.rawValue.split(separator: " ").first.map(String.init) ?? "")

                if viewModel.recordingDuration > 0 {
                    StreamingStat(label: "Recording", value: viewModel.recordingDurationFormatted, isHighlight: true)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )

            // Server Status - Show QR code and connection info
            if NetworkManager.shared.isServerMode {
                ServerStatusView(
                    ipAddresses: NetworkManager.shared.serverIPAddresses,
                    connectedClients: NetworkManager.shared.connectedClients
                )
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: 20) {
            // App Name
            Text("ARVOS")
                .font(.system(size: 28).weight(.bold))
                .foregroundColor(.primary)

            // Status Message
            VStack(spacing: 6) {
                if !viewModel.isConnected {
                    Text("NOT CONNECTED")
                        .font(.system(.caption2))
                        .foregroundColor(.secondary)

                    Text("Configure server connection below")
                        .font(.system(.caption2))
                        .foregroundColor(.secondary.opacity(0.6))
                } else {
                    Text("READY")
                        .font(.system(.caption2).weight(.medium))
                        .foregroundColor(.primary)

                    Text("Select mode and start")
                        .font(.system(.caption2))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding()
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(StreamMode.allCases) { mode in
                        ModeCard(
                            mode: mode,
                            isSelected: viewModel.selectedMode == mode,
                            action: { viewModel.selectMode(mode) }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 120)

            // Inline Custom Mode Selector
            if viewModel.selectedMode == .custom {
                customModeSensorSelector
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedMode)
    }

    // MARK: - Custom Mode Sensor Selector

    private var customModeSensorSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Sensors")
                .font(.system(.subheadline).weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                CustomSensorToggle(
                    icon: "camera.fill",
                    label: "Camera",
                    isEnabled: viewModel.customCameraEnabled,
                    action: { viewModel.toggleCustomCamera() }
                )

                CustomSensorToggle(
                    icon: "cube.fill",
                    label: "Depth",
                    isEnabled: viewModel.customDepthEnabled,
                    action: { viewModel.toggleCustomDepth() }
                )

                CustomSensorToggle(
                    icon: "gyroscope",
                    label: "IMU",
                    isEnabled: viewModel.customIMUEnabled,
                    action: { viewModel.toggleCustomIMU() }
                )

                CustomSensorToggle(
                    icon: "location.fill",
                    label: "Pose",
                    isEnabled: viewModel.customPoseEnabled,
                    action: { viewModel.toggleCustomPose() }
                )

                CustomSensorToggle(
                    icon: "map.fill",
                    label: "GPS",
                    isEnabled: viewModel.customGPSEnabled,
                    action: { viewModel.toggleCustomGPS() }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Supporting Views

struct MetricBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body).weight(.medium))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(.caption2))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
        )
    }
}

struct StreamingStat: View {
    let label: String
    let value: String
    var isHighlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3).weight(.semibold).monospacedDigit())
                .foregroundColor(isHighlight ? .red : .primary)

            Text(label)
                .font(.system(.caption2).weight(.medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

struct SensorBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(label)
                .font(.system(.caption2).weight(.medium))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct CustomSensorToggle: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isEnabled ? .white : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isEnabled ? Color.accentColor : Color(.systemGray5))
                    )

                Text(label)
                    .font(.system(.subheadline).weight(.medium))
                    .foregroundColor(isEnabled ? .primary : .secondary)

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isEnabled ? .accentColor : .secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModeCard: View {
    let mode: StreamMode
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isSelected ? (colorScheme == .dark ? .black : .white) : .primary)
                    .frame(height: 20)

                Text(mode.rawValue.uppercased())
                    .font(.system(.caption2).weight(.semibold))
                    .foregroundColor(isSelected ? (colorScheme == .dark ? .black : .white) : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(mode.description)
                    .font(.system(.caption2))
                    .foregroundColor(isSelected ? (colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.8)) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 36)
            }
            .frame(width: 110, height: 90)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? (colorScheme == .dark ? Color.white : Color.primary) : Color(.secondarySystemBackground))
            )
        }
    }
}

// MARK: - Data Source Picker

struct DataSourcePicker: View {
    @EnvironmentObject var viewModel: StreamingViewModel
    @Environment(\.dismiss) var dismiss

    @State private var cameraEnabled = true
    @State private var depthEnabled = true
    @State private var imuEnabled = true
    @State private var poseEnabled = true
    @State private var gpsEnabled = true

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 8) {
                        Text("DATA SOURCES")
                            .font(.system(.headline).weight(.bold))

                        Text("Configure sensor inputs")
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("SENSORS") {
                    DataSourceToggle(
                        icon: "camera.fill",
                        title: "Camera",
                        subtitle: "RGB video • 30 FPS",
                        isOn: $cameraEnabled
                    )

                    DataSourceToggle(
                        icon: "cube.fill",
                        title: "Depth / LiDAR",
                        subtitle: "Point cloud • 5 FPS",
                        isOn: $depthEnabled
                    )

                    DataSourceToggle(
                        icon: "gyroscope",
                        title: "IMU",
                        subtitle: "Accel & gyro • 100 Hz",
                        isOn: $imuEnabled
                    )

                    DataSourceToggle(
                        icon: "location.fill",
                        title: "6DOF Pose",
                        subtitle: "ARKit tracking • 30 Hz",
                        isOn: $poseEnabled
                    )

                    DataSourceToggle(
                        icon: "map.fill",
                        title: "GPS",
                        subtitle: "Location • 1 Hz",
                        isOn: $gpsEnabled
                    )
                }

                Section {
                    Button {
                        viewModel.updateDataSources(
                            camera: cameraEnabled,
                            depth: depthEnabled,
                            imu: imuEnabled,
                            pose: poseEnabled,
                            gps: gpsEnabled
                        )
                        dismiss()
                    } label: {
                        Text("APPLY")
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.primary)
                            .cornerRadius(8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DataSourceToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body).weight(.medium))

                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Bento Box Cards

struct BentoCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)

            Spacer()

            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(.caption2))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemBackground))
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
