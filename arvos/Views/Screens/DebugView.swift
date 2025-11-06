//
//  DebugView.swift
//  arvos
//
//  Debug console and performance monitoring
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var viewModel: StreamingViewModel

    var body: some View {
        NavigationView {
            List {
                Section("Sensor Status") {
                    StatusRow(label: "Camera", status: viewModel.sensorStatuses.camera)
                    StatusRow(label: "Depth", status: viewModel.sensorStatuses.depth)
                    StatusRow(label: "IMU", status: viewModel.sensorStatuses.imu)
                    StatusRow(label: "Pose", status: viewModel.sensorStatuses.pose)
                    StatusRow(label: "GPS", status: viewModel.sensorStatuses.gps)
                }

                Section("Performance") {
                    HStack {
                        Text("FPS")
                        Spacer()
                        Text(viewModel.fpsFormatted)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Recording Duration")
                        Spacer()
                        Text(viewModel.recordingDurationFormatted)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Recording Size")
                        Spacer()
                        Text(viewModel.recordingSizeFormatted)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Connection") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(viewModel.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(viewModel.isConnected ? .green : .red)
                    }

                    HStack {
                        Text("Host")
                        Spacer()
                        Text(viewModel.connectionHost.isEmpty ? "Not set" : viewModel.connectionHost)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Port")
                        Spacer()
                        Text(viewModel.connectionPort)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Mode Configuration") {
                    HStack {
                        Text("Current Mode")
                        Spacer()
                        Text(viewModel.selectedMode.rawValue)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Camera Enabled")
                        Spacer()
                        Text(viewModel.selectedMode.config.cameraEnabled ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Depth Enabled")
                        Spacer()
                        Text(viewModel.selectedMode.config.depthEnabled ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("IMU Enabled")
                        Spacer()
                        Text(viewModel.selectedMode.config.imuEnabled ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Recording Enabled")
                        Spacer()
                        Text(viewModel.selectedMode.config.recordingEnabled ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Device Info") {
                    HStack {
                        Text("Model")
                        Spacer()
                        Text(UIDevice.current.model)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Device Name")
                        Spacer()
                        Text(UIDevice.current.name)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Debug")
        }
    }
}

struct StatusRow: View {
    let label: String
    let status: SensorStatus

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(status.rawValue)
                    .foregroundColor(.secondary)
            }
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

#Preview {
    DebugView()
        .environmentObject(StreamingViewModel())
}
