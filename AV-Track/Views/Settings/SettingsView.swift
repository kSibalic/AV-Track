//
//  SettingsView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 04.03.2026..
//

import SwiftUI
import Auth

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("printerIPAddress") private var printerIP = ""
    @State private var authManager = AuthManager.shared
    @State private var syncViewModel = SyncViewModel()

    var body: some View {
        Form {
            printerSection
            syncSection
            aboutSection
        }
        .navigationTitle("Settings")
        .onAppear {
            syncViewModel.refreshPendingCount(modelContext: modelContext)
        }
    }

    // MARK: - Printer
    private var printerSection: some View {
        Section {
            LabeledContent {
                TextField("e.g. 192.168.1.100", text: $printerIP)
                    .textContentType(.URL)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Printer IP", systemImage: "printer.fill")
            }
        } header: {
            Text("Brother PT-E550W")
        } footer: {
            Text("The IP address of your label printer on the local Wi-Fi network.")
        }
    }

    // MARK: - Sync & Auth
    private var syncSection: some View {
        Section {
            if let user = authManager.session?.user {
                LabeledContent {
                    Text(user.email ?? "Unknown Email")
                        .foregroundStyle(.secondary)
                } label: {
                    Label("Logged In As", systemImage: "person.circle.fill")
                }
            }
            
            LabeledContent {
                if syncViewModel.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("\(syncViewModel.pendingCount)")
                        .foregroundStyle(syncViewModel.pendingCount > 0 ? .orange : .secondary)
                }
            } label: {
                Label("Pending Mutations", systemImage: "arrow.triangle.2.circlepath")
            }
            
            if let error = syncViewModel.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Button {
                Task {
                    await syncViewModel.forceSync(modelContext: modelContext)
                }
            } label: {
                Label("Sync Now", systemImage: "arrow.clockwise")
            }
            .disabled(syncViewModel.isSyncing || syncViewModel.pendingCount == 0 || !syncViewModel.isConnected)
            
            if !syncViewModel.isConnected {
                Label("Waiting for connection...", systemImage: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            Button(role: .destructive) {
                Task {
                    await authManager.logout()
                }
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } header: {
            Text("Supabase")
        } footer: {
            Text("Configuration for the backend database and syncing engine.")
        }
    }

    // MARK: - About
    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: "AV-Track")
            LabeledContent("Version", value: "1.0.0")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
