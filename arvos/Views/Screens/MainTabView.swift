//
//  MainTabView.swift
//  arvos
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = StreamingViewModel()
    @State private var showTestView = false

    var body: some View {
        TabView {
            // Stream Tab
            NavigationStack {
                StreamView()
                    .navigationBarTitleDisplayMode(.inline)
                    .environmentObject(viewModel)
            }
            .tabItem {
                Label("Stream", systemImage: "video.circle.fill")
            }

            // Sensor Test Tab
            NavigationStack {
                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            Image(systemName: "sensor.tag.radiowaves.forward.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.blue)

                            VStack(spacing: 8) {
                                Text("Sensor Test Mode")
                                    .font(.title2.bold())

                                Text("Inspect LiDAR, camera and IMU feeds before streaming.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }

                            Button {
                                showTestView = true
                            } label: {
                                Label("Start Testing", systemImage: "play.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(
                                PrimaryActionButtonStyle(isRunning: false)
                            )
                        }
                        .padding(32)
                        .frame(maxWidth: min(proxy.size.width * 0.6, 420))
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                        .padding(.horizontal, max((proxy.size.width - min(proxy.size.width * 0.6, 420)) / 2, 24))
                        .padding(.vertical, max((proxy.size.height - 360) / 4, 32))
                    }
                    .background(Color(.systemGroupedBackground))
                }
                .navigationTitle("Test")
            }
            .tabItem {
                Label("Test", systemImage: "waveform.path.ecg")
            }
            .sheet(isPresented: $showTestView) {
                SensorTestView()
            }

            // Files Tab
            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }

            // Settings Tab (includes diagnostics)
            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
