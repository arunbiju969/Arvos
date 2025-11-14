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
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()

                    VStack(spacing: 32) {
                        Spacer()

                        VStack(spacing: 16) {
                            Text("Sensor Test")
                                .font(.system(size: 32, weight: .bold))

                            Text("Inspect LiDAR, camera and IMU feeds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Start Test Button
                        Button {
                            showTestView = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .medium))

                                Text("START TEST")
                                    .font(.system(.subheadline).weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                ZStack {
                                    Color.black
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                        }
                        .padding(.horizontal, 40)

                        Spacer()
                    }
                }
                .navigationTitle("Test")
                .navigationBarTitleDisplayMode(.inline)
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
