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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Control Section
                    controlSection

                    // LiDAR Point Cloud Preview
                    if viewModel.showLiDAR && viewModel.latestPointCloud != nil {
                        lidarSection
                    }

                    // Camera Preview
                    if viewModel.showCamera {
                        cameraSection
                    }

                    // IMU Data
                    if viewModel.showIMU {
                        imuSection
                    }

                    // Pose Data
                    if viewModel.showPose {
                        poseSection
                    }

                    // GPS Data
                    if viewModel.showGPS {
                        gpsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
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
        .onDisappear {
            viewModel.stopTesting()
        }
    }

    // MARK: - Control Section

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SENSORS")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Toggle("LiDAR Point Cloud", isOn: $viewModel.showLiDAR)
                Toggle("Camera Feed", isOn: $viewModel.showCamera)
                Toggle("IMU (Accel + Gyro)", isOn: $viewModel.showIMU)
                Toggle("6DOF Pose", isOn: $viewModel.showPose)
                Toggle("GPS Location", isOn: $viewModel.showGPS)
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - LiDAR Section

    private var lidarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cube.fill")
                    .foregroundColor(.purple)
                Text("LiDAR Point Cloud")
                    .font(.headline)
                Spacer()
                if let cloud = viewModel.latestPointCloud {
                    Text("\(cloud.points.count) points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let pointCloud = viewModel.latestPointCloud {
                PointCloudMetalView(pointCloud: pointCloud)
                    .frame(height: 300)
                    .cornerRadius(8)
            } else {
                Text("Waiting for depth data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Camera Section

    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                Text("Camera Feed")
                    .font(.headline)
                Spacer()
                if let resolution = viewModel.cameraResolution {
                    Text(resolution)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let image = viewModel.latestCameraImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(8)
            } else {
                Text("Waiting for camera frame...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - IMU Section

    private var imuSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gyroscope")
                    .foregroundColor(.orange)
                Text("IMU Data")
                    .font(.headline)
            }

            if let imu = viewModel.latestIMU {
                VStack(spacing: 8) {
                    DataRow(
                        label: "Accel (m/s²)",
                        x: imu.linearAcceleration.x,
                        y: imu.linearAcceleration.y,
                        z: imu.linearAcceleration.z
                    )
                    DataRow(
                        label: "Gyro (rad/s)",
                        x: imu.angularVelocity.x,
                        y: imu.angularVelocity.y,
                        z: imu.angularVelocity.z
                    )
                    DataRow(
                        label: "Gravity (m/s²)",
                        x: imu.gravity.x,
                        y: imu.gravity.y,
                        z: imu.gravity.z
                    )
                }
            } else {
                Text("Waiting for IMU data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Pose Section

    private var poseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text("6DOF Pose")
                    .font(.headline)
                Spacer()
                if let pose = viewModel.latestPose {
                    Text(pose.trackingState)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pose.isTrackingGood ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(pose.isTrackingGood ? .green : .orange)
                        .cornerRadius(4)
                }
            }

            if let pose = viewModel.latestPose {
                VStack(spacing: 8) {
                    DataRow(
                        label: "Position (m)",
                        x: Double(pose.position.x),
                        y: Double(pose.position.y),
                        z: Double(pose.position.z)
                    )
                    HStack {
                        Text("Orientation:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "x:%.2f y:%.2f z:%.2f w:%.2f",
                                    pose.orientation.x, pose.orientation.y, pose.orientation.z, pose.orientation.w))
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            } else {
                Text("Waiting for pose data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - GPS Section

    private var gpsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.red)
                Text("GPS Location")
                    .font(.headline)
            }

            if let gps = viewModel.latestGPS {
                VStack(spacing: 8) {
                    HStack {
                        Text("Latitude:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.6f°", gps.latitude))
                            .font(.system(.caption, design: .monospaced))
                    }
                    HStack {
                        Text("Longitude:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.6f°", gps.longitude))
                            .font(.system(.caption, design: .monospaced))
                    }
                    HStack {
                        Text("Altitude:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.1f m", gps.altitude))
                            .font(.system(.caption, design: .monospaced))
                    }
                    HStack {
                        Text("Accuracy:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "±%.1f m", gps.horizontalAccuracy))
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            } else {
                Text("Waiting for GPS fix...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Supporting Views

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

#Preview {
    SensorTestView()
}
