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
        VStack(spacing: 16) {
            Text("📡 Server Running")
                .font(.system(.headline).weight(.semibold))

            // QR Code for first IP
            if let firstIP = ipAddresses.first,
               let qrImage = QRCodeGenerator.generateForWebSocket(ip: firstIP) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            // Connection URLs
            VStack(spacing: 8) {
                Text("Connect Studio to:")
                    .font(.system(.caption).weight(.medium))
                    .foregroundColor(.secondary)

                ForEach(ipAddresses, id: \.self) { ip in
                    Text("ws://\(ip):8765")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(6)
                }
            }

            // Client counter
            HStack(spacing: 6) {
                Image(systemName: connectedClients > 0 ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 14))
                    .foregroundColor(connectedClients > 0 ? .green : .secondary)

                Text("\(connectedClients) client(s) connected")
                    .font(.system(.caption2))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
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
