import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = SettingsViewModel()
    @State private var showingDisconnect = false

    var body: some View {
        Form {
            Section("Server Connection") {
                TextField("Server URL", text: $viewModel.serverURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                TextField("Username (optional)", text: $viewModel.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                SecureField("Password (optional)", text: $viewModel.password)
                    .textContentType(.password)
            }

            Section {
                Button {
                    Task {
                        if let error = await viewModel.save() {
                            // show error
                        } else {
                            await appVM.connect()
                            dismiss()
                        }
                    }
                } label: {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if appVM.isConnected {
                Section("Connection Info") {
                    LabeledContent("Status", value: appVM.isConnected ? "Connected" : "Disconnected")
                    if !appVM.serverVersion.isEmpty {
                        LabeledContent("Version", value: appVM.serverVersion)
                    }
                    LabeledContent("Sessions", value: "\(appVM.sessions.count)")
                    LabeledContent("Agents", value: "\(appVM.agents.count)")
                }

                Section {
                    Button(role: .destructive) {
                        showingDisconnect = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Disconnect")
                            Spacer()
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await viewModel.clearAll()
                        await appVM.disconnect()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Clear All Data")
                        Spacer()
                    }
                }
            } footer: {
                Text("This removes all stored server credentials from your device.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            await viewModel.load()
        }
        .alert("Disconnect?", isPresented: $showingDisconnect) {
            Button("Disconnect", role: .destructive) {
                appVM.disconnect()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
