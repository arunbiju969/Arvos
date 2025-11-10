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
            StreamView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Stream", systemImage: "video.circle.fill")
                }

            // Sensor Test Tab
            NavigationView {
                VStack {
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Sensor Test Mode")
                            .font(.title2.bold())

                        Text("View all sensors in real-time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            showTestView = true
                        } label: {
                            Text("Start Testing")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }

                    Spacer()
                }
                .navigationTitle("Test")
            }
            .tabItem {
                Label("Test", systemImage: "waveform.path.ecg")
            }
            .sheet(isPresented: $showTestView) {
                SensorTestView()
            }

            // Settings Tab
            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }

            // Files Tab
            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }

            // Debug Tab
            DebugView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Debug", systemImage: "ant.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
