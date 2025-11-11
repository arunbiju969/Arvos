//
//  SettingsView.swift
//  arvos
//
//  Settings and configuration
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: StreamingViewModel
    @State private var cameraFPS: Double = 30
    @State private var imuHz: Double = 100
    @State private var depthFPS: Double = 10
    @State private var poseHz: Double = 30

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Camera FPS")
                        Spacer()
                        Text("\(Int(cameraFPS))")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $cameraFPS, in: 1...30, step: 1) {
                        Text("Camera FPS")
                    } minimumValueLabel: {
                        Text("1")
                    } maximumValueLabel: {
                        Text("30")
                    }
                    .onChange(of: cameraFPS) { oldValue, newValue in
                        viewModel.updateCameraFPS(Int(newValue))
                    }
                } header: {
                    Text("Camera")
                }

                Section {
                    HStack {
                        Text("Depth FPS")
                        Spacer()
                        Text("\(Int(depthFPS))")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $depthFPS, in: 1...10, step: 1) {
                        Text("Depth FPS")
                    } minimumValueLabel: {
                        Text("1")
                    } maximumValueLabel: {
                        Text("10")
                    }
                    .onChange(of: depthFPS) { oldValue, newValue in
                        viewModel.updateDepthFPS(Int(newValue))
                    }
                } header: {
                    Text("Depth / LiDAR")
                }

                Section {
                    HStack {
                        Text("IMU Frequency")
                        Spacer()
                        Text("\(Int(imuHz)) Hz")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $imuHz, in: 50...400, step: 50) {
                        Text("IMU Hz")
                    } minimumValueLabel: {
                        Text("50")
                    } maximumValueLabel: {
                        Text("400")
                    }
                    .onChange(of: imuHz) { oldValue, newValue in
                        viewModel.updateIMUHz(Int(newValue))
                    }

                    HStack {
                        Text("Pose Frequency")
                        Spacer()
                        Text("\(Int(poseHz)) Hz")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $poseHz, in: 10...60, step: 10) {
                        Text("Pose Hz")
                    } minimumValueLabel: {
                        Text("10")
                    } maximumValueLabel: {
                        Text("60")
                    }
                    .onChange(of: poseHz) { oldValue, newValue in
                        viewModel.updatePoseHz(Int(newValue))
                    }
                } header: {
                    Text("Motion Sensors")
                }

                Section {
                    HStack {
                        Text("Watch Connected")
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(viewModel.sensorManager.watchSensorManager.isWatchConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(viewModel.sensorManager.watchSensorManager.isWatchConnected ? "Yes" : "No")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.sensorManager.watchSensorManager.isWatchConnected {
                        HStack {
                            Text("Watch Sample Rate")
                            Spacer()
                            Text(String(format: "%.1f Hz", viewModel.sensorManager.watchSensorManager.watchHz))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Watch Samples")
                            Spacer()
                            Text("\(viewModel.sensorManager.watchSensorManager.watchSampleCount)")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Pair your Apple Watch and install the arvos Watch app to enable watch sensor streaming.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Apple Watch")
                }

                Section {
                    HStack {
                        Text("Device")
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
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StreamingViewModel())
}
