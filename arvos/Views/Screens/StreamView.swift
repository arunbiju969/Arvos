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
                } else {
                    // iPhone or iPad Portrait: Vertical layout
                    VStack(spacing: 0) {
                        // Top Status Bar
                        topStatusBar
                            .background(Color(.systemBackground))

                        Spacer()

                        // Center Content
                        if viewModel.isStreaming {
                            liveDataBentoBox
                        } else {
                            centerContent
                        }

                        Spacer()

                        // Bottom Controls
                        bottomControls
                            .background(Color(.systemBackground))
                    }
                }
            }
        }
        .sheet(isPresented: $showDataSourcePicker) {
            DataSourcePicker()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingConnectionSheet) {
            ConnectionSheet()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingQRScanner) {
            QRScannerView(scannedCode: $scannedQRCode)
        }
        .onChange(of: scannedQRCode) { _, newValue in
            if let code = newValue {
                viewModel.scanQRCode(code)
                scannedQRCode = nil
            }
        }
    }

    // MARK: - Top Status Bar

    private var topStatusBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Connection Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.orange : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)

                    Text(viewModel.isConnected ? "CONNECTED" : "DISCONNECTED")
                        .font(.system(.caption2).weight(.medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Sensors Button
                Button {
                    showDataSourcePicker = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                }
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
            // Mode Selector (when not streaming)
            if !viewModel.isStreaming {
                modeSelector
            }

            // Main Control Button
            Button {
                viewModel.toggleStreaming()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isStreaming ? "stop.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))

                    Text(viewModel.isStreaming ? "STOP" : "START")
                        .font(.system(.subheadline).weight(.semibold))
                }
                .foregroundColor(viewModel.isStreaming ? Color(.systemBackground) : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.isStreaming ? Color.primary : Color(.systemGray5))
                )
            }

            // Connection Button (when not connected)
            if !viewModel.isConnected && !viewModel.isStreaming {
                Button {
                    viewModel.showingConnectionSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "network")
                            .font(.system(size: 12))
                        Text("CONNECT TO SERVER")
                            .font(.system(.caption).weight(.medium))
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding()
    }

    // MARK: - Live Data Display (Simplified for Performance)

    private var liveDataBentoBox: some View {
        VStack(spacing: 12) {
            // Status Grid
            HStack(spacing: 12) {
                // FPS Card
                BentoCard(
                    icon: "waveform",
                    label: "FPS",
                    value: viewModel.fpsFormatted,
                    color: .orange
                )

                // Recording Card
                if viewModel.recordingDuration > 0 {
                    BentoCard(
                        icon: "record.circle",
                        label: "REC",
                        value: viewModel.recordingDurationFormatted,
                        color: .red
                    )
                } else {
                    BentoCard(
                        icon: "checkmark.circle",
                        label: "LIVE",
                        value: "✓",
                        color: .green
                    )
                }
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
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
        )
    }
}

struct ModeCard: View {
    let mode: StreamMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isSelected ? Color(.systemBackground) : .primary)
                    .frame(height: 20)

                Text(mode.rawValue.uppercased())
                    .font(.system(.caption2).weight(.semibold))
                    .foregroundColor(isSelected ? Color(.systemBackground) : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(mode.description)
                    .font(.system(.caption2))
                    .foregroundColor(isSelected ? Color(.systemBackground).opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 36)
            }
            .frame(width: 110, height: 90)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.primary : Color(.systemGray6))
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
        .tint(.orange)
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
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Removed IMUSensorCard, DepthSensorCard, PoseSensorCard to improve performance

#Preview {
    StreamView()
        .environmentObject(StreamingViewModel())
}
