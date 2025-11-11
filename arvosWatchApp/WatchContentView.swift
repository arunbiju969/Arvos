//
//  WatchContentView.swift
//  arvosWatchApp
//
//  Main watch interface for sensor streaming control
//

import SwiftUI

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
                
                // Stats
                if sensorService.isStreaming {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IMU: \(String(format: "%.0f Hz", sensorService.currentHz))")
                            .font(.caption)
                        Text("Samples: \(sensorService.sampleCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("arvos")
        }
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchConnectivityService.shared)
}

