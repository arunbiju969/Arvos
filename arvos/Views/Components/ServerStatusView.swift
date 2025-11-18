//
//  ServerStatusView.swift
//  arvos
//
//  Displays server connection info with QR code (Foxglove-style)
//

import SwiftUI

struct ServerStatusView: View {
    let ipAddresses: [String]
    let connectedClients: Int

    var body: some View {
        VStack(spacing: 8) {
            // Compact header with client count
            HStack(spacing: 6) {
                Image(systemName: connectedClients > 0 ? "antenna.radiowaves.left.and.right" : "dot.radiowaves.left.and.right")
                    .font(.system(size: 11))
                    .foregroundColor(connectedClients > 0 ? .green : .secondary)

                Text("\(connectedClients) connected")
                    .font(.system(.caption2).weight(.medium))
                    .foregroundColor(.secondary)
            }

            // Compact QR Code
            if let firstIP = ipAddresses.first,
               let qrImage = QRCodeGenerator.generateForWebSocket(ip: firstIP) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(8)
            }

            // Just show the primary IP (usually the WiFi one)
            if let primaryIP = ipAddresses.first(where: { $0.hasPrefix("192.168") || $0.hasPrefix("10.") }) ?? ipAddresses.first {
                Text(primaryIP)
                    .font(.system(.caption, design: .monospaced).weight(.medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    ServerStatusView(
        ipAddresses: ["192.168.1.100", "10.0.0.50"],
        connectedClients: 1
    )
    .padding()
    .background(Color(.systemBackground))
}
