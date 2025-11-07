//
//  StreamMode.swift
//  arvos
//
//  Core streaming modes with specific sensor configurations
//

import Foundation

/// Streaming mode defining which sensors to use and at what rates
enum StreamMode: String, Codable, CaseIterable, Identifiable {
    case liveStream = "Live Stream"
    case mapping = "Mapping"
    case telemetry = "Telemetry"
    case burstScan = "Burst Scan"
    case lowPower = "Low Power"
    case replay = "Replay"

    var id: String { rawValue }

    /// User-facing description of the mode
    var description: String {
        switch self {
        case .liveStream:
            return "Low-latency streaming for live visualization and monitoring"
        case .mapping:
            return "High-fidelity synchronized data for 3D reconstruction and SLAM"
        case .telemetry:
            return "Lightweight streaming for long-term logging and navigation"
        case .burstScan:
            return "Short high-quality capture triggered manually (30-60s)"
        case .lowPower:
            return "Minimal sensors to maximize battery life for extended use"
        case .replay:
            return "Stream from recorded files at original timestamps"
        }
    }

    /// SF Symbol icon for the mode
    var icon: String {
        switch self {
        case .liveStream:
            return "video.circle.fill"
        case .mapping:
            return "cube.transparent.fill"
        case .telemetry:
            return "chart.xyaxis.line"
        case .burstScan:
            return "camera.metering.spot"
        case .lowPower:
            return "battery.100.bolt"
        case .replay:
            return "play.circle.fill"
        }
    }

    /// Configuration for this mode
    var config: ModeConfiguration {
        switch self {
        case .liveStream:
            return ModeConfiguration(
                cameraEnabled: true,
                cameraFPS: 10,
                depthEnabled: true,
                depthFPS: 5,
                imuEnabled: true,
                imuHz: 100,
                poseEnabled: true,
                poseHz: 30,
                gpsEnabled: true,  // Enable GPS for visualization
                recordingEnabled: false,
                autoDuration: nil
            )
        case .mapping:
            return ModeConfiguration(
                cameraEnabled: true,
                cameraFPS: 30,
                depthEnabled: true,
                depthFPS: 10,
                imuEnabled: true,
                imuHz: 200,
                poseEnabled: true,
                poseHz: 60,
                gpsEnabled: true,
                recordingEnabled: true,
                autoDuration: nil
            )
        case .telemetry:
            return ModeConfiguration(
                cameraEnabled: false,
                cameraFPS: 0,
                depthEnabled: false,
                depthFPS: 0,
                imuEnabled: true,
                imuHz: 100,
                poseEnabled: true,
                poseHz: 30,
                gpsEnabled: true,
                recordingEnabled: false,
                autoDuration: nil
            )
        case .burstScan:
            return ModeConfiguration(
                cameraEnabled: true,
                cameraFPS: 30,
                depthEnabled: true,
                depthFPS: 10,
                imuEnabled: true,
                imuHz: 200,
                poseEnabled: true,
                poseHz: 60,
                gpsEnabled: false,
                recordingEnabled: true,
                autoDuration: 60 // Auto-stop after 60 seconds
            )
        case .lowPower:
            return ModeConfiguration(
                cameraEnabled: true,
                cameraFPS: 2,
                depthEnabled: false,
                depthFPS: 0,
                imuEnabled: true,
                imuHz: 50,
                poseEnabled: false,
                poseHz: 0,
                gpsEnabled: false,
                recordingEnabled: false,
                autoDuration: nil
            )
        case .replay:
            return ModeConfiguration(
                cameraEnabled: false,
                cameraFPS: 0,
                depthEnabled: false,
                depthFPS: 0,
                imuEnabled: false,
                imuHz: 0,
                poseEnabled: false,
                poseHz: 0,
                gpsEnabled: false,
                recordingEnabled: false,
                autoDuration: nil
            )
        }
    }
}

/// Configuration parameters for a streaming mode
struct ModeConfiguration: Codable {
    var cameraEnabled: Bool
    var cameraFPS: Int
    var depthEnabled: Bool
    var depthFPS: Int
    var imuEnabled: Bool
    var imuHz: Int
    var poseEnabled: Bool
    var poseHz: Int
    var gpsEnabled: Bool
    var recordingEnabled: Bool
    var autoDuration: TimeInterval? // Auto-stop duration in seconds
}
