//
//  AccessPointModeView.swift
//  arvos
//
//  UI for Personal Hotspot / Direct WiFi connection mode
//

import SwiftUI

struct AccessPointModeView: View {
    @StateObject private var apService = AccessPointService()
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "wifi.router")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Direct WiFi Connection")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Lower latency • No router required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Divider()
                
                // Status Section
                if apService.isHotspotActive {
                    activeHotspotView
                } else {
                    inactiveHotspotView
                }
                
                Divider()
                
                // Information Section
                informationSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Direct Connection")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Active Hotspot View
    
    private var activeHotspotView: some View {
        VStack(spacing: 20) {
            // Success indicator
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title)
                
                Text("Personal Hotspot Active")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            // Hotspot Details & Instructions
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Network Name:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(apService.hotspotSSID)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("On your computer")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Text("1. Connect to '\(apService.hotspotSSID)' hotspot\n2. Run 'examples/direct_wifi_connection.py' from the SDK\n3. Use the QR code *from the computer* to connect")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "iphone")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("On this iPhone")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Text("Tap \"Scan QR\" or manually enter the URL shown on your computer (usually ws://<computer-ip>:9090)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("The iPhone connects to the server running on your computer. Use the address provided by the desktop script (not this iPhone's IP).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // QR Code
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "terminal")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Desktop steps")
                            .font(.headline)
                        Text("1. On your Mac, open Terminal and run:\n   python3 examples/direct_wifi_connection.py\n2. A QR code will appear on the Mac – this is the one to scan from the iPhone.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "hand.tap")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Connect from iPhone")
                            .font(.headline)
                        Text("• In the connection sheet, set Host to your Mac’s IP (shown in the Mac script) and Port to 9090, then tap CONNECT.\n• Or tap Scan QR and point the camera at the QR displayed on your Mac.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.red)
                    Text("If the Mac firewall is enabled, allow python3 (or your terminal) to accept incoming connections so the iPhone can reach the server.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("To Connect:")
                    .font(.headline)
                
                instructionStep(number: 1, text: "Connect your computer to '\(apService.hotspotSSID)' WiFi")
                instructionStep(number: 2, text: "Run your receiver app/script")
                instructionStep(number: 3, text: "Use the URL or scan the QR code above")
                instructionStep(number: 4, text: "Start streaming!")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Refresh Button
            Button(action: {
                isRefreshing = true
                apService.detectHotspot()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isRefreshing = false
                }
            }) {
                Label("Refresh Status", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRefreshing)
        }
    }
    
    // MARK: - Inactive Hotspot View
    
    private var inactiveHotspotView: some View {
        VStack(spacing: 20) {
            // Warning indicator
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title)
                
                Text("Personal Hotspot Not Active")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            // Setup Instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("How to Enable:")
                    .font(.headline)
                
                instructionStep(number: 1, text: "Open Settings app")
                instructionStep(number: 2, text: "Tap 'Personal Hotspot'")
                instructionStep(number: 3, text: "Turn ON 'Allow Others to Join'")
                instructionStep(number: 4, text: "Note your WiFi password")
                instructionStep(number: 5, text: "Return to this app")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Open Settings Button
            Button(action: {
                if let url = URL(string: "App-Prefs:root=INTERNET_TETHERING") {
                    UIApplication.shared.open(url)
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Label("Open Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            // Check Again Button
            Button(action: {
                isRefreshing = true
                apService.detectHotspot()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isRefreshing = false
                }
            }) {
                Label(isRefreshing ? "Checking..." : "Check Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshing)
        }
    }
    
    // MARK: - Information Section
    
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Use Direct Connection?")
                .font(.headline)
            
            benefitRow(icon: "bolt.fill", color: .yellow, title: "Lower Latency", description: "Direct device-to-device connection reduces lag")
            
            benefitRow(icon: "wifi.slash", color: .blue, title: "No Router Needed", description: "Works anywhere without WiFi network")
            
            benefitRow(icon: "lock.shield.fill", color: .green, title: "More Secure", description: "Data stays between your devices")
            
            benefitRow(icon: "gauge.high", color: .orange, title: "Better Performance", description: "Maximize throughput without network congestion")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func benefitRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - QR Code View

struct QRCodeView: View {
    let url: String
    
    var body: some View {
        if let qrImage = generateQRCode(from: url) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("QR Code\nUnavailable")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                )
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

#if DEBUG
struct AccessPointModeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccessPointModeView()
        }
    }
}
#endif

