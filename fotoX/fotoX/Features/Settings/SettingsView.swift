//
//  SettingsView.swift
//  fotoX
//
//  Operator settings screen
//

import SwiftUI

/// Settings screen for operator configuration
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = SettingsViewModel()
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Connection settings
                        connectionSection

                        // Capture settings
                        captureSettingsSection

                        // App info
                        appInfoSection

                        // Danger zone
                        dangerZoneSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.saveSettings() {
                            updateAPIClient()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset Session", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    appState.resetSession()
                    dismiss()
                }
            } message: {
                Text("This will cancel the current session and return to the idle screen.")
            }
        }
    }
    
    // MARK: - Connection Section
    
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Worker Connection", icon: "network")
            
            VStack(spacing: 12) {
                // URL input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Base URL")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("https://your-worker.workers.dev", text: $viewModel.baseURLString)
                        .textFieldStyle(.plain)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    viewModel.urlError != nil ? Color.red.opacity(0.5) : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    
                    if let error = viewModel.urlError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // Presign token
                VStack(alignment: .leading, spacing: 6) {
                    Text("Presign Token")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SecureField("Shared presign token", text: $viewModel.presignToken)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    Text("Required for uploads via /presign")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Test connection button
                HStack {
                    Button {
                        Task {
                            await viewModel.testConnection()
                        }
                    } label: {
                        HStack {
                            if viewModel.isTestingConnection {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text("Test Connection")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.opacity(0.1))
                        )
                    }
                    .disabled(viewModel.isTestingConnection)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        viewModel.resetToDefault()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                // Test result
                if let result = viewModel.connectionTestResult {
                    connectionTestResultView(result: result)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    private func connectionTestResultView(result: ConnectionTestResult) -> some View {
        HStack {
            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Connection successful!")
                    .foregroundStyle(.green)
            case .failure(let message):
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .foregroundStyle(.red)
            }
            
            Spacer()
        }
        .font(.subheadline)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(result == .success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }

    // MARK: - Capture Settings Section

    private var captureSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Capture Settings", icon: "video.circle")

            VStack(spacing: 0) {
                // Video duration control
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Video Duration")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Text("Length of each video recording")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Text("\(Int(viewModel.videoDuration))s")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.primary)
                            .frame(minWidth: 40, alignment: .trailing)

                        Stepper("", value: $viewModel.videoDuration, in: 3...10, step: 1)
                            .labelsHidden()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .padding(.leading, 16)

                // Frame text overlays toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show Frame Text")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Text("Display couple's names and date on photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.frameTextOverlays)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "App Info", icon: "info.circle")
            
            VStack(spacing: 0) {
                infoRow(label: "Version", value: appVersion)
                Divider().padding(.leading, 16)
                infoRow(label: "Build", value: appBuild)
                Divider().padding(.leading, 16)
                infoRow(label: "Current Event", value: appState.selectedEvent?.name ?? "None")
                
                if appState.currentSession != nil {
                    Divider().padding(.leading, 16)
                    infoRow(label: "Active Session", value: "Yes")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Danger Zone
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Session Control", icon: "exclamationmark.triangle")
            
            VStack(spacing: 12) {
                if appState.currentSession != nil {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Current Session")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.red.opacity(0.1))
                        )
                    }
                }
                
                Button {
                    appState.returnToEventSelection()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.circle")
                        Text("Return to Event Selection")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.orange.opacity(0.1))
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
    }
    
    private func updateAPIClient() {
        // The APIClient will read from UserDefaults on next request
        // For immediate effect, the app would need to be restarted
        // or services reinitialized
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
