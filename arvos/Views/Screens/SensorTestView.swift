//
//  SensorTestView.swift
//  arvos
//
//  Real-time sensor visualization and testing view
//

import SwiftUI
import ARKit
import CoreMotion

struct SensorTestView: View {
    @StateObject private var viewModel = SensorTestViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var useSimpleRenderer = false
    @State private var isFullscreen = false
    
    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= 900
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 24, alignment: .top), count: isWide ? 2 : 1)

            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                NavigationStack {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 24) {
                            statusHeader
                                .gridCellColumns(isWide ? 2 : 1)

                            controlSection

                            if viewModel.showLiDAR {
                                lidarSection
                                    .gridCellColumns(isWide ? 2 : 1)
                            }

                            if viewModel.showCamera {
                                cameraSection
                            }

                            if viewModel.showIMU {
                                imuSection
                            }

                            if viewModel.showPose {
                                poseSection
                            }

                            if viewModel.showGPS {
                                gpsSection
                            }

                            if viewModel.showWatch {
                                watchSection
                            }
                        }
                        .padding(.horizontal, isWide ? 32 : 20)
                        .padding(.vertical, 24)
                        .frame(maxWidth: 1080)
                        .frame(maxWidth: .infinity)
                    }
                    .background(Color.clear)
                    .navigationTitle("Sensor Test")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { dismiss() }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(viewModel.isRunning ? "Stop" : "Start") {
                                viewModel.toggleTesting()
                            }
                            .foregroundColor(viewModel.isRunning ? .red : .blue)
                        }
                    }
                }

                // Fullscreen LiDAR overlay
                if isFullscreen, let depthSample = viewModel.latestDepthSample {
                    fullscreenLiDARView(depthSample: depthSample)
                }
            }
            .onDisappear {
                viewModel.stopTesting()
            }
        }
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                StatusBadge(
                    icon: viewModel.isRunning ? "dot.radiowaves.left.and.right" : "pause.circle.fill",
                    title: viewModel.isRunning ? "Live Stream" : "Not Streaming",
                    tint: viewModel.isRunning ? .accentColor : .secondary
                )
                
                if viewModel.isRunning {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 1, height: 28)
                    
                    Text("Telemetry updates will appear as soon as data is available.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            if let lastUpdate = viewModel.lastSensorUpdate {
                Label {
                    Text("Last update \(lastUpdate, style: .relative).")
                } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
                Text(viewModel.isRunning ? "Waiting for first sensor sample…" : "Start a session to view live telemetry.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sensorCardStyle()
    }
    
    // MARK: - Control Section
    
    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                viewModel.toggleTesting()
            } label: {
                Label(
                    viewModel.isRunning ? "Stop Testing" : "Start Testing",
                    systemImage: viewModel.isRunning ? "stop.fill" : "play.circle.fill"
                )
            }
            .buttonStyle(PrimaryActionButtonStyle(isRunning: viewModel.isRunning))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Sensor Modules")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Enable only the feeds you need. Disabling a module pauses its UI updates but keeps the stream active.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                sensorToggle(
                    title: "LiDAR Point Cloud",
                    subtitle: "Metal visualizer & resolution metrics",
                    icon: "cube.fill",
                    binding: $viewModel.showLiDAR
                )
                sensorToggle(
                    title: "Camera Feed",
                    subtitle: "Latest camera frame preview",
                    icon: "camera.fill",
                    binding: $viewModel.showCamera
                )
                sensorToggle(
                    title: "IMU (Accel + Gyro)",
                    subtitle: "Linear acceleration, gyroscope, gravity",
                    icon: "gyroscope",
                    binding: $viewModel.showIMU
                )
                sensorToggle(
                    title: "6DOF Pose",
                    subtitle: "Position vectors & tracking status",
                    icon: "location.north.line.fill",
                    binding: $viewModel.showPose
                )
                sensorToggle(
                    title: "GPS Location",
                    subtitle: "Lat/Lon coordinates & accuracy",
                    icon: "map.fill",
                    binding: $viewModel.showGPS
                )
                sensorToggle(
                    title: "Apple Watch",
                    subtitle: "Watch IMU & wearable sensors",
                    icon: "applewatch",
                    binding: $viewModel.showWatch
                )
            }
        }
        .sensorCardStyle()
    }
    
    // MARK: - LiDAR Section
    
    private var lidarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(
                icon: "cube.fill",
                title: "LiDAR Depth Point Cloud",
                trailing: {
                    HStack(spacing: 8) {
                        if viewModel.isRunning {
                            LivePill()
                        }
                        if let sample = viewModel.latestDepthSample {
                            Text("\(sample.width)×\(sample.height)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.primary.opacity(0.06)))
                        }
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isFullscreen = true
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .padding(10)
                                .background(Circle().fill(Color.accentColor.opacity(0.12)))
                        }
                    }
                }
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Renderer Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Renderer", selection: $useSimpleRenderer) {
                    Text("Full fidelity").tag(false)
                    Text("Metal test").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal, 4)
            
            if let sample = viewModel.latestDepthSample {
                if useSimpleRenderer {
                    SimpleDepthView(depthSample: sample)
                        .frame(maxWidth: .infinity)
                        .frame(height: 480)
                        .background(Color.black)
                        .cornerRadius(12)
                        .overlay(alignment: .topLeading) {
                            Text("Test mode renders three diagnostic markers (RGB).")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(8)
                                .padding(10)
                        }
                } else {
                    DepthPointCloudView(depthSample: sample)
                        .frame(maxWidth: .infinity)
                        .frame(height: 480)
                        .background(Color.black)
                        .cornerRadius(12)
                }
            } else {
                LoadingCard(message: "Initializing LiDAR…")
                    .frame(height: 420)
            }
        }
        .sensorCardStyle()
    }

    // MARK: - Camera Section

    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                icon: "camera.fill",
                title: "Camera Feed",
                trailing: {
                    if let resolution = viewModel.cameraResolution {
                        Text(resolution)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                }
            )

            Group {
                if let image = viewModel.latestCameraImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                } else {
                    LoadingCard(message: "Waiting for camera frame…")
                        .frame(height: 220)
                }
            }
        }
        .sensorCardStyle()
    }

    // MARK: - IMU Section

    private var imuSection: some View {
        sensorDataSection(
            icon: "gyroscope",
            title: "IMU Data",
            content: {
                if let imu = viewModel.latestIMU {
                    VStack(spacing: 10) {
                        DataRow(
                            label: "Accel (m/s²)",
                            x: imu.linearAcceleration.x,
                            y: imu.linearAcceleration.y,
                            z: imu.linearAcceleration.z
                        )
                        Divider()
                        DataRow(
                            label: "Gyro (rad/s)",
                            x: imu.angularVelocity.x,
                            y: imu.angularVelocity.y,
                            z: imu.angularVelocity.z
                        )
                        Divider()
                        DataRow(
                            label: "Gravity (m/s²)",
                            x: imu.gravity.x,
                            y: imu.gravity.y,
                            z: imu.gravity.z
                        )
                    }
                } else {
                    LoadingCard(message: "Waiting for IMU data…", useDarkBackground: false)
                }
            }
        )
    }

    // MARK: - Pose Section

    private var poseSection: some View {
        sensorDataSection(
            icon: "location.fill",
            title: "6DOF Pose",
            trailing: {
                if let pose = viewModel.latestPose {
                    let statusColor = pose.isTrackingGood ? Color.accentColor : Color.secondary
                    Text(pose.trackingState)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.15))
                        )
                }
            },
            content: {
                if let pose = viewModel.latestPose {
                    VStack(alignment: .leading, spacing: 12) {
                        DataRow(
                            label: "Position (m)",
                            x: Double(pose.position.x),
                            y: Double(pose.position.y),
                            z: Double(pose.position.z)
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Orientation (Quaternion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(
                                String(
                                    format: "x:%.2f  y:%.2f  z:%.2f  w:%.2f",
                                    pose.orientation.x,
                                    pose.orientation.y,
                                    pose.orientation.z,
                                    pose.orientation.w
                                )
                            )
                            .font(.system(.caption, design: .monospaced))
                        }
                    }
                } else {
                    LoadingCard(message: "Waiting for pose data…", useDarkBackground: false)
                }
            }
        )
    }

    // MARK: - GPS Section

    private var gpsSection: some View {
        sensorDataSection(
            icon: "map.fill",
            title: "GPS Location",
            content: {
                if let gps = viewModel.latestGPS {
                    VStack(alignment: .leading, spacing: 10) {
                        metricRow(label: "Latitude", value: String(format: "%.6f°", gps.latitude))
                        metricRow(label: "Longitude", value: String(format: "%.6f°", gps.longitude))
                        metricRow(label: "Altitude", value: String(format: "%.1f m", gps.altitude))
                        metricRow(label: "Accuracy", value: String(format: "±%.1f m", gps.horizontalAccuracy))
                    }
                } else {
                    LoadingCard(message: "Waiting for GPS fix…", useDarkBackground: false)
                }
            }
        )
    }
    
    // MARK: - Watch Section
    
    private var watchSection: some View {
        sensorDataSection(
            icon: "applewatch",
            title: "Apple Watch",
            trailing: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.watchConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.watchConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            },
            content: {
                if viewModel.watchConnected {
                    VStack(alignment: .leading, spacing: 10) {
                        metricRow(label: "Sample Rate", value: String(format: "%.1f Hz", viewModel.watchHz))
                        
                        if let watchIMU = viewModel.latestWatchIMU {
                            Divider()
                            
                            Text("Angular Velocity (rad/s)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            metricRow(label: "X", value: String(format: "%.3f", watchIMU.angularVelocity.x))
                            metricRow(label: "Y", value: String(format: "%.3f", watchIMU.angularVelocity.y))
                            metricRow(label: "Z", value: String(format: "%.3f", watchIMU.angularVelocity.z))
                            
                            Divider()
                            
                            Text("Linear Acceleration (m/s²)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            metricRow(label: "X", value: String(format: "%.3f", watchIMU.linearAcceleration.x))
                            metricRow(label: "Y", value: String(format: "%.3f", watchIMU.linearAcceleration.y))
                            metricRow(label: "Z", value: String(format: "%.3f", watchIMU.linearAcceleration.z))
                        } else {
                            LoadingCard(message: "Waiting for IMU samples…", useDarkBackground: false)
                        }
                        
                        if let attitude = viewModel.latestWatchAttitude {
                            Divider()
                            Text("Attitude")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            metricRow(label: "Pitch", value: formatAngle(attitude.pitch))
                            metricRow(label: "Roll", value: formatAngle(attitude.roll))
                            metricRow(label: "Yaw", value: formatAngle(attitude.yaw))
                        }
                        
                        if let activity = viewModel.latestWatchActivity {
                            Divider()
                            Text("Activity Classification")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            metricRow(label: "State", value: activity.descriptionLabel.capitalized)
                            metricRow(label: "Confidence", value: activity.confidenceDescription)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "applewatch.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Watch Not Connected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Pair your Apple Watch and ensure the arvos Watch app is installed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        )
    }

    // MARK: - Shared Builders

    @ViewBuilder
    private func sensorDataSection<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> some View = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: icon, title: title, trailing: trailing)
            content()
        }
        .sensorCardStyle()
    }

    private func sensorToggle(
        title: String,
        subtitle: String,
        icon: String,
        binding: Binding<Bool>
    ) -> some View {
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        .padding(.vertical, 6)
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(.caption, design: .monospaced))
        }
    }
    
    private func formatAngle(_ value: Double) -> String {
        let degrees = value * 180 / .pi
        return String(format: "%.1f°", degrees)
    }

    @ViewBuilder
    private func sectionHeader(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(width: 26)

            Text(title)
                .font(.headline)

            Spacer()

            trailing()
        }
    }

    // MARK: - Fullscreen LiDAR View

    @ViewBuilder
    private func fullscreenLiDARView(depthSample: DepthVisualizationSample) -> some View {
        ZStack {
            // Fullscreen point cloud
            DepthPointCloudView(depthSample: depthSample)
                .ignoresSafeArea()
                .background(Color.black)

            // Sensor data overlay
            VStack {
                // Top: Exit button + resolution info
                HStack {
                    Button {
                        withAnimation {
                            isFullscreen = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }

                    Spacer()

                    Text("\(depthSample.width)×\(depthSample.height)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                }
                .padding()

                Spacer()

                // Bottom: Sensor data box
                VStack(alignment: .leading, spacing: 8) {
                    // IMU Data
                    if let imu = viewModel.latestIMU {
                        SensorDataBox(title: "IMU", icon: "gyroscope", color: .accentColor) {
                            CompactDataRow(label: "Accel", x: imu.linearAcceleration.x, y: imu.linearAcceleration.y, z: imu.linearAcceleration.z, unit: "m/s²")
                            CompactDataRow(label: "Gyro", x: imu.angularVelocity.x, y: imu.angularVelocity.y, z: imu.angularVelocity.z, unit: "rad/s")
                        }
                    }

                    // Pose Data
                    if let pose = viewModel.latestPose {
                        SensorDataBox(title: "POSE", icon: "location.fill", color: .accentColor) {
                            CompactDataRow(label: "Pos", x: Double(pose.position.x), y: Double(pose.position.y), z: Double(pose.position.z), unit: "m")
                            HStack(spacing: 4) {
                                let statusColor = pose.isTrackingGood ? Color.accentColor : Color.secondary
                                Text(pose.trackingState)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(statusColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(statusColor.opacity(0.2)))
                            }
                        }
                    }

                    // GPS Data
                    if let gps = viewModel.latestGPS {
                        SensorDataBox(title: "GPS", icon: "map.fill", color: .accentColor) {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.5f°", gps.latitude))
                                        .font(.system(.caption2, design: .monospaced))
                                    Text(String(format: "%.5f°", gps.longitude))
                                        .font(.system(.caption2, design: .monospaced))
                                }
                                Text(String(format: "±%.0fm", gps.horizontalAccuracy))
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
    }
}

struct LivePill: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
            Text("Live")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.accentColor.opacity(0.16)))
        .foregroundColor(.accentColor)
    }
}

struct LoadingCard: View {
    let message: String
    var useDarkBackground: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(useDarkBackground ? Color.black : Color.primary.opacity(0.04))
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: useDarkBackground ? .white : .accentColor))
                    .scaleEffect(1.1)
                Text(message)
                    .font(.caption)
                    .foregroundColor(useDarkBackground ? Color.white.opacity(0.8) : .secondary)
            }
            .padding()
        }
    }
}

struct DataRow: View {
    let label: String
    let x: Double
    let y: Double
    let z: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(String(format: "x:%.2f y:%.2f z:%.2f", x, y, z))
                .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - Fullscreen Overlay Components

struct SensorDataBox<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            content
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
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
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 36, alignment: .leading)
            Text(String(format: "x:%.2f y:%.2f z:%.2f", x, y, z))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.white)
            Text(unit)
                .font(.system(.caption2))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    let isRunning: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(
                        colors: isRunning
                            ? [Color.accentColor.opacity(0.92), Color.accentColor]
                            : [Color.accentColor.opacity(0.88), Color.accentColor]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func sensorCardStyle() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            
    }
}

#Preview {
    SensorTestView()
}
