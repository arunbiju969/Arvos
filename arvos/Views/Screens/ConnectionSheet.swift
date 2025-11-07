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
            Form {
                Section {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        TextField("Host (e.g., 192.168.1.100)", text: $viewModel.connectionHost)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }

                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        TextField("Port", text: $viewModel.connectionPort)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("Manual Connection")
                } footer: {
                    Text("Enter the IP address and port of your computer running the Arvos server.")
                }

                Section {
                    Button(action: {
                        viewModel.showingQRScanner = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundColor(.blue)

                            Text("Scan QR Code")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Quick Setup")
                } footer: {
                    Text("Scan a QR code from your Arvos server to connect automatically.")
                }

                Section {
                    Button(action: {
                        viewModel.connectToServer()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Connect")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.connectionHost.isEmpty)
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
