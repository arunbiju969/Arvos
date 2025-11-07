//
//  StreamView.swift
//  arvos
//
//  Main streaming view with camera preview and controls
//

import SwiftUI

struct StreamView: View {
    @EnvironmentObject var viewModel: StreamingViewModel

    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview (background)
                if viewModel.isStreaming {
                    CameraPreviewView()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                }

                // Overlay UI
                VStack(spacing: 0) {
                    // Top Status Bar
                    topStatusBar
                        .padding()
                        .background(.ultraThinMaterial)

                    Spacer()

                    // Bottom Controls
                    bottomControls
                        .padding()
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingConnectionSheet) {
                ConnectionSheet()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showingQRScanner) {
                QRScannerView(scannedCode: Binding(
                    get: { nil },
                    set: { if let code = $0 { viewModel.scanQRCode(code) } }
                ))
            }
        }
    }

    // MARK: - Top Status Bar

    private var topStatusBar: some View {
        VStack(spacing: 12) {
            // Connection Status
            HStack {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                Text(viewModel.isConnected ? "Connected" : "Disconnected")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Text(viewModel.selectedMode.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }

            // Sensor Status
            HStack(spacing: 16) {
                SensorStatusBadge(name: "Camera", status: viewModel.sensorStatuses.camera)
                SensorStatusBadge(name: "Depth", status: viewModel.sensorStatuses.depth)
                SensorStatusBadge(name: "IMU", status: viewModel.sensorStatuses.imu)
                SensorStatusBadge(name: "Pose", status: viewModel.sensorStatuses.pose)
                SensorStatusBadge(name: "GPS", status: viewModel.sensorStatuses.gps)
            }

            // Performance Metrics
            if viewModel.isStreaming {
                HStack(spacing: 24) {
                    MetricView(label: "FPS", value: viewModel.fpsFormatted)

                    if viewModel.recordingDuration > 0 {
                        MetricView(label: "Recording", value: viewModel.recordingDurationFormatted)
                        MetricView(label: "Size", value: viewModel.recordingSizeFormatted)
                    }

                    if let remaining = viewModel.burstScanRemainingTime {
                        MetricView(label: "Remaining", value: remaining)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Mode Selector
            if !viewModel.isStreaming {
                modeSelector
            }

            // Main Control Button
            Button(action: {
                viewModel.toggleStreaming()
            }) {
                HStack {
                    Image(systemName: viewModel.isStreaming ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)

                    Text(viewModel.isStreaming ? "Stop Streaming" : "Start Streaming")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isStreaming ? Color.red : Color.blue)
                .cornerRadius(Constants.UI.cornerRadius)
            }

            // Connection Button
            if !viewModel.isConnected && !viewModel.isStreaming {
                Button(action: {
                    viewModel.showingConnectionSheet = true
                }) {
                    HStack {
                        Image(systemName: "wifi")
                        Text("Connect to Server")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(Constants.UI.cornerRadius)
                }
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StreamMode.allCases) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: viewModel.selectedMode == mode,
                        action: {
                            viewModel.selectMode(mode)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        // TODO: Add camera preview layer
        // Would need to expose previewLayer from CameraService

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Supporting Views

struct SensorStatusBadge: View {
    let name: String
    let status: SensorStatus

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .inactive:
            return .gray
        case .active:
            return .green
        case .error:
            return .red
        }
    }
}

struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body, design: .monospaced).weight(.medium))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ModeCard: View {
    let mode: StreamMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(mode.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(mode.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 120)
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(Constants.UI.cornerRadius)
        }
    }
}

#Preview {
    StreamView()
        .environmentObject(StreamingViewModel())
}
