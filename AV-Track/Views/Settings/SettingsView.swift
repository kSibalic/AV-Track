//
//  SettingsView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 04.03.2026..
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("printerIPAddress") private var printerIP = ""
    @AppStorage("supabaseURL") private var supabaseURL = ""
    @AppStorage("supabaseAnonKey") private var supabaseAnonKey = ""

    var body: some View {
        Form {
            printerSection
            syncSection
            aboutSection
        }
        .navigationTitle("Settings")
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

    // MARK: - Sync
    private var syncSection: some View {
        Section {
            LabeledContent {
                TextField("https://your-project.supabase.co", text: $supabaseURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Project URL", systemImage: "link")
            }

            LabeledContent {
                SecureField("Anon key", text: $supabaseAnonKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Anon Key", systemImage: "key")
            }

            // TODO: Sync status
            LabeledContent {
                Text("—")
                    .foregroundStyle(.secondary)
            } label: {
                Label("Pending Mutations", systemImage: "arrow.triangle.2.circlepath")
            }

            Button {
                // TODO: Manual sync trigger
            } label: {
                Label("Sync Now", systemImage: "arrow.clockwise")
            }
            .disabled(supabaseURL.isEmpty || supabaseAnonKey.isEmpty)
        } header: {
            Text("Supabase")
        } footer: {
            Text("Configure your Supabase project credentials. All data syncs automatically when online.")
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
