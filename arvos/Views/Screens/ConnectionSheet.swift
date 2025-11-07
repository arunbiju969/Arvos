//
//  ConnectionSheet.swift
//  arvos
//
//  Connection setup sheet with QR scanner and manual entry
//

import SwiftUI

struct ConnectionSheet: View {
    @EnvironmentObject var viewModel: StreamingViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Manual Connection Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Manual Connection")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "network")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    TextField("Host (e.g., 192.168.1.100)", text: $viewModel.connectionHost)
                                        .textContentType(.URL)
                                        .keyboardType(.URL)
                                        .autocapitalization(.none)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )

                                HStack {
                                    Image(systemName: "number")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    TextField("Port", text: $viewModel.connectionPort)
                                        .keyboardType(.numberPad)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            Text("Enter the IP address and port of your computer running the Arvos server.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        )

                        // Quick Setup Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Setup")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                viewModel.showingQRScanner = true
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "qrcode.viewfinder")
                                        .foregroundColor(.blue)
                                        .font(.title2)

                                    Text("Scan QR Code")
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            Text("Scan a QR code from your Arvos server to connect automatically.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        )
                        
                        // Connect Button
                        Button(action: {
                            viewModel.connectToServer()
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Connect")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.blue.opacity(0.5), radius: 10, y: 5)
                            )
                        }
                        .disabled(viewModel.connectionHost.isEmpty)
                        .opacity(viewModel.connectionHost.isEmpty ? 0.6 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Connect to Server")
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

#Preview {
    ConnectionSheet()
        .environmentObject(StreamingViewModel())
}
