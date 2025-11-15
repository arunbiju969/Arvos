//
//  OnboardingView.swift
//  arvos
//
//  Interactive onboarding and tutorial system for first-time users
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to ARVOS",
            description: "Transform your iPhone into a powerful sensor streaming platform for AR, robotics, and 3D reconstruction.",
            systemImage: "camera.metering.multispot"
        ),
        OnboardingPage(
            title: "Stream Rich Sensor Data",
            description: "Access camera, LiDAR depth, IMU, GPS, and pose data in real-time over WiFi or Bluetooth.",
            systemImage: "sensor.fill"
        ),
        OnboardingPage(
            title: "Multiple Protocols",
            description: "Choose from WebSocket, gRPC, MQTT, QUIC, or HTTP/REST to fit your workflow.",
            systemImage: "network"
        ),
        OnboardingPage(
            title: "Record Everything",
            description: "Save sensor data to MCAP format for playback, analysis, and offline processing.",
            systemImage: "opticaldiscdrive.fill"
        ),
        OnboardingPage(
            title: "Apple Watch Support",
            description: "Pair your Apple Watch to stream additional IMU data and motion activity.",
            systemImage: "applewatch"
        ),
        OnboardingPage(
            title: "Ready to Stream",
            description: "Connect to your receiver using WiFi or scan a QR code to get started instantly.",
            systemImage: "antenna.radiowaves.left.and.right"
        )
    ]

    var body: some View {
        ZStack {
            // Clean dark background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Last page - show "Get Started" button
                        Button(action: completeOnboarding) {
                            HStack {
                                Text("Get Started")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                    } else {
                        // Other pages - show "Next" button
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            HStack {
                                Text("Next")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            isPresented = false
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon - clean monochromatic
            Image(systemName: page.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.white)

            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Quick Tips View

struct QuickTipsView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                Section("Streaming") {
                    TipRow(
                        icon: "qrcode.viewfinder",
                        title: "Quick Connect",
                        description: "Scan a QR code from your receiver to connect instantly"
                    )
                    TipRow(
                        icon: "network",
                        title: "Choose Your Protocol",
                        description: "WebSocket is fastest for local networks, gRPC for production"
                    )
                    TipRow(
                        icon: "sensor.fill",
                        title: "Sensor Modes",
                        description: "Full Sensor captures everything, Burst Scan for quick scans"
                    )
                }

                Section("Recording") {
                    TipRow(
                        icon: "record.circle",
                        title: "Save to MCAP",
                        description: "Record sensor data for later playback and analysis"
                    )
                    TipRow(
                        icon: "externaldrive",
                        title: "Manage Storage",
                        description: "Check Files tab to view, share, or delete recordings"
                    )
                }

                Section("Apple Watch") {
                    TipRow(
                        icon: "applewatch",
                        title: "Pair Your Watch",
                        description: "Install the Watch app for additional IMU and activity data"
                    )
                }

                Section("Performance") {
                    TipRow(
                        icon: "bolt.fill",
                        title: "Adjust Frame Rates",
                        description: "Lower FPS to reduce network usage and battery drain"
                    )
                    TipRow(
                        icon: "battery.100",
                        title: "Battery Life",
                        description: "Disable unused sensors and reduce resolution to extend runtime"
                    )
                }
            }
            .navigationTitle("Quick Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

#Preview("Quick Tips") {
    QuickTipsView(isPresented: .constant(true))
}
