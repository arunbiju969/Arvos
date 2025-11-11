//
//  WatchContentView.swift
//  arvosWatchApp
//
//  Main watch interface for sensor streaming control
//

import SwiftUI
import CoreMotion

struct WatchContentView: View {
    @EnvironmentObject var connectivityService: WatchConnectivityService
    @StateObject private var sensorService = WatchSensorService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Connection status
                HStack {
                    Circle()
                        .fill(connectivityService.isPhoneReachable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(connectivityService.isPhoneReachable ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Streaming control
                Button(action: {
                    if sensorService.isStreaming {
                        sensorService.stopStreaming()
                    } else {
                        sensorService.startStreaming()
                    }
                }) {
                    VStack {
                        Image(systemName: sensorService.isStreaming ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                        Text(sensorService.isStreaming ? "Stop" : "Start")
                            .font(.headline)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(sensorService.isStreaming ? .red : .green)
                
                if sensorService.isStreaming {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IMU: \(String(format: "%.0f Hz", sensorService.currentHz))")
                            Text("Samples: \(sensorService.sampleCount)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        if let attitude = sensorService.latestAttitude {
                            Divider()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Attitude").font(.caption.bold())
                                Text("Pitch: \(formatAngle(attitude.pitch))")
                                Text("Roll: \(formatAngle(attitude.roll))")
                                Text("Yaw: \(formatAngle(attitude.yaw))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        if let activity = sensorService.latestActivity {
                            Divider()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Activity").font(.caption.bold())
                                Text(activityDescription(activity))
                                Text("Confidence: \(confidenceString(activity.confidence))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        if let gesture = sensorService.latestGesture {
                            Divider()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gesture").font(.caption.bold())
                                Text("\(gesture.label.capitalized) • \(String(format: "%.0f%%", gesture.confidence * 100))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("arvos")
        }
    }
    
    private func formatAngle(_ value: Double) -> String {
        let degrees = value * 180 / .pi
        return String(format: "%.1f°", degrees)
    }
    
    private func confidenceString(_ raw: Int) -> String {
        switch raw {
        case CMMotionActivityConfidence.low.rawValue:
            return "Low"
        case CMMotionActivityConfidence.medium.rawValue:
            return "Medium"
        case CMMotionActivityConfidence.high.rawValue:
            return "High"
        default:
            return "Unknown"
        }
    }
    
    private func activityDescription(_ activity: WatchMotionActivityData) -> String {
        if activity.isRunning { return "Running" }
        if activity.isWalking { return "Walking" }
        if activity.isCycling { return "Cycling" }
        if activity.isDriving { return "In Vehicle" }
        if activity.isStationary { return "Stationary" }
        return "Unknown"
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchConnectivityService.shared)
}

