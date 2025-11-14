//
//  SensorTestView.swift
//  arvos
//
//  Dashboard-style sensor testing view with full-screen LiDAR/depth and minimizable overlays
//

import SwiftUI
import ARKit
import CoreMotion

struct SensorTestView: View {
    @StateObject private var viewModel = SensorTestViewModel()
    @State private var cameraBoxMinimized = false
    @State private var sensorBoxMinimized = false
    @State private var hasLiDAR: Bool = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Full-screen LiDAR/Depth background
                    Color.black
                        .ignoresSafeArea()
                    
                    // Main depth/LiDAR view
                    if let depthSample = viewModel.latestDepthSample {
                        // Point cloud view mode
                        if hasLiDAR {
                            DepthPointCloudView(depthSample: depthSample)
                                .ignoresSafeArea()
                        } else {
                            SimpleDepthView(depthSample: depthSample)
                                .ignoresSafeArea()
                        }
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            Text(viewModel.isRunning ? "Initializing depth sensor…" : "Tap Start to begin")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Top status bar
                    VStack {
                        HStack {
                            // Status indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(viewModel.isRunning ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                
                                Text(viewModel.isRunning ? "LIVE" : "STOPPED")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )
                            
                            Spacer()
                            
                            // Device capability indicator
                            if hasLiDAR {
                                HStack(spacing: 4) {
                                    Image(systemName: "cube.fill")
                                        .font(.system(size: 10))
                                    Text("LiDAR")
                                        .font(.system(.caption2, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.6))
                                )
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "cube.transparent.fill")
                                        .font(.system(size: 10))
                                    Text("DEPTH")
                                        .font(.system(.caption2, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.6))
                                )
                            }
                        }
                        .padding()
                        
                        Spacer()
                    }
                    
                    // Minimizable Camera Box (top-right)
                    VStack {
                        HStack {
                            Spacer()
                            
                            if !cameraBoxMinimized {
                                cameraOverlayBox
                                    .frame(width: min(geometry.size.width * 0.35, 200))
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            } else {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        cameraBoxMinimized = false
                                    }
                                } label: {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                    
                    // Minimizable Sensor Data Box (bottom-left)
                    VStack {
                        Spacer()
                        
                        HStack {
                            if !sensorBoxMinimized {
                                sensorDataOverlayBox
                                    .frame(width: min(geometry.size.width * 0.45, 240))
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            } else {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        sensorBoxMinimized = false
                                    }
                                } label: {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 100)
                    }
                    
                    // Bottom controls
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button {
                                viewModel.toggleTesting()
                            } label: {
                                Text(viewModel.isRunning ? "Stop" : "Start")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(viewModel.isRunning ? Color.red : Color.accentColor)
                                    )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Sensor Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.isRunning ? "Stop" : "Start") {
                        viewModel.toggleTesting()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.isRunning ? .red : .primary)
                }
            }
        }
        .onAppear {
            // Check for LiDAR capability
            hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        }
    }
    
    // MARK: - Camera Overlay Box
    
    private var cameraOverlayBox: some View {
        VStack(spacing: 0) {
            // Header with minimize button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("CAMERA")
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                
                Spacer()
                
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        cameraBoxMinimized = true
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            
            // Camera feed
                if let image = viewModel.latestCameraImage {
                    Image(uiImage: image)
                        .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                } else {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(height: 120)
                    .overlay {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Waiting…")
                                .font(.system(.caption2))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Sensor Data Overlay Box
    
    private var sensorDataOverlayBox: some View {
        VStack(spacing: 0) {
            // Header with minimize button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("SENSORS")
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)

            Spacer()

                    Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        sensorBoxMinimized = true
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            
            // Sensor data content
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // IMU Data
                    if let imu = viewModel.latestIMU {
                        SensorDataRow(
                            icon: "gyroscope",
                            label: "IMU",
                            content: {
                                VStack(alignment: .leading, spacing: 4) {
                            CompactDataRow(label: "Accel", x: imu.linearAcceleration.x, y: imu.linearAcceleration.y, z: imu.linearAcceleration.z, unit: "m/s²")
                            CompactDataRow(label: "Gyro", x: imu.angularVelocity.x, y: imu.angularVelocity.y, z: imu.angularVelocity.z, unit: "rad/s")
                        }
                            }
                        )
                    }

                    // Pose Data
                    if let pose = viewModel.latestPose {
                        SensorDataRow(
                            icon: "location.fill",
                            label: "POSE",
                            content: {
                                VStack(alignment: .leading, spacing: 4) {
                            CompactDataRow(label: "Pos", x: Double(pose.position.x), y: Double(pose.position.y), z: Double(pose.position.z), unit: "m")
                            HStack(spacing: 4) {
                                        let statusColor = pose.isTrackingGood ? Color.green : Color.orange
                                        Circle()
                                            .fill(statusColor)
                                            .frame(width: 6, height: 6)
                                Text(pose.trackingState)
                                    .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                        )
                    }

                    // GPS Data
                    if let gps = viewModel.latestGPS {
                        SensorDataRow(
                            icon: "map.fill",
                            label: "GPS",
                            content: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: "%.5f°", gps.latitude))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(String(format: "%.5f°", gps.longitude))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(String(format: "±%.0fm", gps.horizontalAccuracy))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        )
                    }
                    
                    // Watch Data
                    if viewModel.watchConnected {
                        SensorDataRow(
                            icon: "applewatch",
                            label: "WATCH",
                            content: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text(String(format: "%.1f Hz", viewModel.watchHz))
                                    .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        )
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 200)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Views

struct SensorDataRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Text(label)
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
            }

            content
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct CompactDataRow: View {
    let label: String
    let x: Double
    let y: Double
    let z: Double
    let unit: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 40, alignment: .leading)
            Text(String(format: "%.2f,%.2f,%.2f", x, y, z))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
            Text(unit)
                .font(.system(.caption2))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    SensorTestView()
}
