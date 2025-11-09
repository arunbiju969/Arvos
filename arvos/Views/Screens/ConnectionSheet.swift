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

#Preview {
    ConnectionSheet()
        .environmentObject(StreamingViewModel())
}
