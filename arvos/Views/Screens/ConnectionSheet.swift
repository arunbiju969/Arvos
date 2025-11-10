//
//  ConnectionSheet.swift
//  arvos
//
//  Connection setup sheet
//

import SwiftUI

struct ConnectionSheet: View {
    @EnvironmentObject var viewModel: StreamingViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.primary)
                            .frame(width: 30)

                        TextField("Host (e.g., 192.168.1.100)", text: $viewModel.connectionHost)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }

                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.primary)
                            .frame(width: 30)

                        TextField("Port", text: $viewModel.connectionPort)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("SERVER DETAILS")
                } footer: {
                    Text("Enter the IP address and port of your server")
                }

                Section {
                    Button {
                        viewModel.showingQRScanner = true
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundColor(.primary)

                            Text("Scan QR Code")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("QUICK SETUP")
                } footer: {
                    Text("Scan QR code from your server")
                }

                // Connection Status & Diagnostics
                if viewModel.isConnected {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected")
                                .foregroundColor(.green)
                            Spacer()
                            Button("Disconnect") {
                                viewModel.disconnect()
                            }
                            .foregroundColor(.red)
                        }
                    } header: {
                        Text("STATUS")
                    }
                }

                Section {
                    Button {
                        viewModel.connectToServer()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("CONNECT")
                                .font(.system(.subheadline).weight(.semibold))
                            Spacer()
                        }
                    }
                    .disabled(viewModel.connectionHost.isEmpty)
                }

                // Troubleshooting Tips
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TroubleshootTip(
                            icon: "wifi",
                            title: "Same Network",
                            detail: "Ensure both devices are on the same WiFi network"
                        )

                        TroubleshootTip(
                            icon: "network",
                            title: "Firewall",
                            detail: "Check that your server's firewall allows the port"
                        )

                        TroubleshootTip(
                            icon: "server.rack",
                            title: "Server Running",
                            detail: "Verify your WebSocket server is running and listening"
                        )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("TROUBLESHOOTING")
                } footer: {
                    Text("Common connection issues and solutions")
                }
            }
            .navigationTitle("Server Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TroubleshootTip: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline).weight(.medium))
                    .foregroundColor(.primary)

                Text(detail)
                    .font(.system(.caption))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ConnectionSheet()
        .environmentObject(StreamingViewModel())
}
