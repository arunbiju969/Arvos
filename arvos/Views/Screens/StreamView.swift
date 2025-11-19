//
//  StreamView.swift
//  arvos
//
//  Clean device control interface design
//

import SwiftUI

struct StreamView: View {
    @EnvironmentObject var viewModel: StreamingViewModel
    @State private var scannedQRCode: String?
    @State private var showingModeSelector = false
    @State private var fpsHistory: [Double] = []
    @State private var imuMagnitudeHistory: [Double] = []
    @State private var fpsTimer: Timer?
    @State private var imuTimer: Timer?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
        ZStack {
            // Background
                Color(.systemBackground)
                .ignoresSafeArea()

            // Main Content
                VStack(spacing: 0) {
                    // Top Header Bar
                    topHeaderBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, isLandscape ? 12 : 20)

                    // Main Content Area - fills all available space
                    if viewModel.isStreaming {
                        streamingBentoGrid
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        idleContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Action Buttons
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34)
                }
            }
        }
        .onAppear {
            startDataCollection()
        }
        .onDisappear {
            stopDataCollection()
        }
        .onChange(of: viewModel.isStreaming) { isStreaming in
            if isStreaming {
                startDataCollection()
            } else {
                stopDataCollection()
            }
        }
        .onChange(of: viewModel.currentFPS) { newValue in
            if viewModel.isStreaming {
                updateFPSHistory(newValue)
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
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Scan QR Code")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingQRScanner) {
            QRScannerView(scannedCode: $scannedQRCode)
        }
        .sheet(isPresented: $showingModeSelector) {
            ModeSelectorSheet(
                selectedMode: $viewModel.selectedMode,
                customCameraEnabled: $viewModel.customCameraEnabled,
                customDepthEnabled: $viewModel.customDepthEnabled,
                customIMUEnabled: $viewModel.customIMUEnabled,
                customPoseEnabled: $viewModel.customPoseEnabled,
                customGPSEnabled: $viewModel.customGPSEnabled
            )
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

    // MARK: - Top Header Bar

    private var topHeaderBar: some View {
        HStack {
            // ARVOS text (top left, smaller)
                        Text("ARVOS")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            // Status (top right, smaller)
            HStack(spacing: 6) {
                            Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

    private var statusText: String {
        if viewModel.isStreaming {
            return "Streaming"
        } else if NetworkManager.shared.connectedClients > 0 {
            return "Ready"
        } else {
            return "Idle"
        }
    }

    private var statusColor: Color {
        if viewModel.isStreaming {
            return Theme.recording
        } else if NetworkManager.shared.connectedClients > 0 {
            return Theme.success
        } else {
            return Color.secondary.opacity(0.3)
        }
    }

    // MARK: - Idle Content

    private var idleContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Center the metrics
                idleStatusMetrics
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Streaming Bento Grid

    private var streamingBentoGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer(minLength: 0)
                // Row 1: FPS Chart + Mode/Recording Boxes (separate, stacked)
            HStack(spacing: 12) {
                    // FPS Chart Box (flexible, takes most space)
                BentoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "gauge")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                Text("FPS")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Text(viewModel.fpsFormatted)
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            // Simple line chart
                            if !fpsHistory.isEmpty {
                                FPSChartView(data: fpsHistory)
                                    .frame(minHeight: 120, maxHeight: 150)
                            } else {
                                Rectangle()
                                    .fill(Color(.systemGray5).opacity(0.3))
                                    .frame(height: 100)
                                    .cornerRadius(4)
                            }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)

                    // Mode + Recording Boxes (separate, in VStack)
                    VStack(spacing: 12) {
                        // Mode Box (small)
                        BentoCard {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.selectedMode.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                                Text(viewModel.selectedMode.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(width: 140)
                        .frame(height: 90)
                        
                        // Recording Box (small)
                        BentoCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "record.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.recording)
                                    Text("Recording")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                if viewModel.recordingDuration > 0 {
                                    Text(formatDuration(viewModel.recordingDuration))
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.recording)
                                    
                                    Text(viewModel.recordingSizeFormatted)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Not Recording")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(width: 140)
                        .frame(height: 90)
                    }
                }

                // Row 2: IMU Chart + Server Box
                HStack(spacing: 12) {
                    // IMU Chart Box (smaller)
                BentoCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "gyroscope")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("IMU Magnitude")
                                    .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            }
                            Text(String(format: "%.2f", imuMagnitudeHistory.last ?? 0.0))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            // IMU chart
                            if !imuMagnitudeHistory.isEmpty {
                                IMUChartView(data: imuMagnitudeHistory)
                                    .frame(minHeight: 80, maxHeight: 100)
                            } else {
                                Rectangle()
                                    .fill(Color(.systemGray5).opacity(0.3))
                                    .frame(height: 60)
                                    .cornerRadius(4)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 140)

                // Server Box (next to IMU)
                if NetworkManager.shared.isServerMode && !NetworkManager.shared.serverIPAddresses.isEmpty {
                    BentoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "network")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("Server IP")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(NetworkManager.shared.connectedClients) client\(NetworkManager.shared.connectedClients == 1 ? "" : "s")")
                                    .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(NetworkManager.shared.serverIPAddresses.prefix(2), id: \.self) { ip in
                                    Text(ip)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .frame(width: 160)
                    .frame(minHeight: 140)
                }
            }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Status Metrics (Idle)

    private var idleStatusMetrics: some View {
        VStack(alignment: .leading, spacing: 20) {
            MetricRow(label: "Status", value: "Off")
            MetricRow(label: "Mode", value: viewModel.selectedMode.rawValue)
            MetricRow(label: "Clients", value: "\(NetworkManager.shared.connectedClients)")
            if viewModel.recordingDuration > 0 {
                MetricRow(label: "Recording", value: formatDuration(viewModel.recordingDuration))
            }
        }
    }

    // MARK: - Data Collection

    private func startDataCollection() {
        // Stop existing timers
        stopDataCollection()
        
        // Update FPS history less frequently for better performance (1 second instead of 0.5)
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.viewModel.isStreaming {
                self.updateFPSHistory(self.viewModel.currentFPS)
            }
        }
        if let timer = fpsTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        // Update IMU history less frequently for better performance (0.5 seconds instead of 0.1)
        imuTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if self.viewModel.isStreaming {
                // Calculate IMU magnitude from latest IMU data
                // For now, use a simple calculation - you can enhance this
                let mockMagnitude = Double.random(in: 0.8...1.2) // Placeholder
                self.updateIMUHistory(mockMagnitude)
            }
        }
        if let timer = imuTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopDataCollection() {
        fpsTimer?.invalidate()
        fpsTimer = nil
        imuTimer?.invalidate()
        imuTimer = nil
    }

    private func updateFPSHistory(_ fps: Double) {
        // Throttle updates - only update if significant change or every 5 updates
        fpsHistory.append(fps)
        // Keep less data for better performance (30 points instead of 50)
        if fpsHistory.count > 30 {
            fpsHistory.removeFirst()
        }
    }

    private func updateIMUHistory(_ magnitude: Double) {
        // Throttle updates - only update if significant change or every 5 updates
        imuMagnitudeHistory.append(magnitude)
        // Keep less data for better performance (50 points instead of 100)
        if imuMagnitudeHistory.count > 50 {
            imuMagnitudeHistory.removeFirst()
        }
    }


    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.isStreaming {
                // Stop button (primary) - visible in both light and dark mode
                Button {
                    viewModel.toggleStreaming()
                } label: {
                    Text("Stop Streaming")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.red)
                        )
                }
                .buttonStyle(.plain)
            } else {
                // Start button (primary) - visible in both light and dark mode
            Button {
                viewModel.toggleStreaming()
            } label: {
                    Text("Start Streaming")
                        .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.success)
                        )
                }
                .buttonStyle(.plain)

                // Change Mode (secondary)
                Button {
                    showingModeSelector = true
                } label: {
                    Text("Change Mode")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(.separator), lineWidth: 1)
                    .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(.systemBackground))
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helper Functions

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Metric Row Component (Like Image)

struct MetricRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Bento Card Component

struct BentoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - FPS Chart View

struct FPSChartView: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            if !data.isEmpty {
                let maxValue = max(data.max() ?? 30, 30)
                let minValue = max(0, (data.min() ?? 0) - 2)
                let range = maxValue - minValue
                
                // Sample data for better performance (only render every Nth point)
                let sampleRate = max(1, data.count / 20) // Max 20 points for rendering
                let sampledData = stride(from: 0, to: data.count, by: sampleRate).map { data[$0] }
                
                Path { path in
                    for (sampledIndex, value) in sampledData.enumerated() {
                        let originalIndex = sampledIndex * sampleRate
                        let x = CGFloat(sampledIndex) / CGFloat(max(sampledData.count - 1, 1)) * geometry.size.width
                        let y = geometry.size.height - (CGFloat(value - minValue) / CGFloat(range)) * geometry.size.height
                        
                        if sampledIndex == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .drawingGroup() // Cache rendering for better performance
            } else {
                // Empty state
                Rectangle()
                    .fill(Color(.systemGray5).opacity(0.3))
            }
        }
    }
}

// MARK: - IMU Chart View

struct IMUChartView: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            if !data.isEmpty {
                let maxValue = max(data.max() ?? 2.0, 2.0)
                let minValue = 0.0
                let range = maxValue - minValue
                
                // Sample data for better performance (only render every Nth point)
                let sampleRate = max(1, data.count / 20) // Max 20 points for rendering
                let sampledData = stride(from: 0, to: data.count, by: sampleRate).map { data[$0] }
                
                Path { path in
                    for (sampledIndex, value) in sampledData.enumerated() {
                        let x = CGFloat(sampledIndex) / CGFloat(max(sampledData.count - 1, 1)) * geometry.size.width
                        let y = geometry.size.height - (CGFloat(value - minValue) / CGFloat(range)) * geometry.size.height
                        
                        if sampledIndex == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.green, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .drawingGroup() // Cache rendering for better performance
            } else {
                // Empty state
                Rectangle()
                    .fill(Color(.systemGray5).opacity(0.3))
            }
        }
    }
}


// MARK: - Sensor Indicator Component

struct SensorIndicator: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.accent)
        )
    }
}

// MARK: - Server Status Compact View

struct ServerStatusCompactView: View {
    let ipAddresses: [String]
    let connectedClients: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("Server")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(connectedClients) client\(connectedClients == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if let firstIP = ipAddresses.first {
                Text(firstIP)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
            .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Mode Selector Sheet

struct ModeSelectorSheet: View {
    @Binding var selectedMode: StreamMode
    @Binding var customCameraEnabled: Bool
    @Binding var customDepthEnabled: Bool
    @Binding var customIMUEnabled: Bool
    @Binding var customPoseEnabled: Bool
    @Binding var customGPSEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(StreamMode.allCases) { mode in
                        ModeOptionCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            action: {
                                selectedMode = mode
                            }
                        )
                    }

                    if selectedMode == .custom {
                        CustomSensorOptions(
                            cameraEnabled: $customCameraEnabled,
                            depthEnabled: $customDepthEnabled,
                            imuEnabled: $customIMUEnabled,
                            poseEnabled: $customPoseEnabled,
                            gpsEnabled: $customGPSEnabled
                        )
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Select Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModeOptionCard: View {
    let mode: StreamMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.black : Color(.secondarySystemBackground))
                    )

                VStack(alignment: .leading, spacing: 4) {
                Text(mode.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(mode.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color(.systemGray6) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomSensorOptions: View {
    @Binding var cameraEnabled: Bool
    @Binding var depthEnabled: Bool
    @Binding var imuEnabled: Bool
    @Binding var poseEnabled: Bool
    @Binding var gpsEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Sensors")
                .font(.system(size: 17, weight: .semibold))
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                SensorToggle(icon: "camera.fill", label: "Camera", isEnabled: $cameraEnabled)
                SensorToggle(icon: "cube.fill", label: "LiDAR Depth", isEnabled: $depthEnabled)
                SensorToggle(icon: "gyroscope", label: "IMU", isEnabled: $imuEnabled)
                SensorToggle(icon: "location.fill", label: "ARKit Pose", isEnabled: $poseEnabled)
                SensorToggle(icon: "map.fill", label: "GPS", isEnabled: $gpsEnabled)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct SensorToggle: View {
    let icon: String
    let label: String
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 32)
                Text(label)
                    .font(.system(size: 16))
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .black))
    }
}

// MARK: - QR Code Validation Extension

extension StreamView {
    private func validateQRCode(_ code: String) -> Bool {
        guard let url = URL(string: code) else {
            return false
        }

        guard let scheme = url.scheme, (scheme == "ws" || scheme == "wss") else {
            return false
        }

        guard let host = url.host, !host.isEmpty else {
            return false
        }

        if let port = url.port {
            guard (1...65535).contains(port) else {
                return false
            }
        }

        return true
    }
}

#Preview {
    StreamView()
        .environmentObject(StreamingViewModel())
}
