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
    @State private var showResetDefaultsConfirmation = false
    @State private var showClearDiagnosticsConfirmation = false

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

                        // Diagnostics
                        diagnosticsSection

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
                            // Delay dismiss to show confirmation briefly
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                dismiss()
                            }
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
            .alert("Reset to Defaults", isPresented: $showResetDefaultsConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetToDefault()
                }
            } message: {
                Text("This will reset the Worker URL and video duration to their default values. The presign token will not be changed.")
            }
            .alert("Clear Diagnostics", isPresented: $showClearDiagnosticsConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.clearDiagnostics()
                }
            } message: {
                Text("This will clear all diagnostic data including connection history and upload statistics.")
            }
            .overlay {
                if viewModel.showSaveConfirmation {
                    saveConfirmationOverlay
                }
            }
        }
    }

    // MARK: - Save Confirmation Overlay

    private var saveConfirmationOverlay: some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Settings saved")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 10)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: viewModel.showSaveConfirmation)
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
                    HStack {
                        Text("Presign Token")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Token status indicator
                        if viewModel.isTokenValid {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text("Configured")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        } else if !viewModel.presignToken.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text("Invalid")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

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
                                .stroke(
                                    viewModel.tokenError != nil ? Color.red.opacity(0.5) : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )

                    if let error = viewModel.tokenError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if viewModel.isTokenValid {
                        Text("Token: \(viewModel.maskedToken)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Required for uploads via /presign")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                        showResetDefaultsConfirmation = true
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

            VStack(spacing: 16) {
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
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Diagnostics Section

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Diagnostics", icon: "chart.bar.xaxis")

            VStack(spacing: 0) {
                // Last connection test
                if let lastTest = viewModel.lastConnectionTest {
                    diagnosticRow(
                        label: "Last Connection Test",
                        value: formatRelativeTime(lastTest.date),
                        status: lastTest.success ? .success : .failure
                    )
                    Divider().padding(.leading, 16)
                }

                // Last upload
                if let lastUpload = viewModel.lastUpload {
                    diagnosticRow(
                        label: "Last Upload",
                        value: formatRelativeTime(lastUpload.date),
                        status: lastUpload.success ? .success : .failure
                    )
                    Divider().padding(.leading, 16)
                }

                // Upload stats
                let stats = viewModel.uploadStats
                if stats.total > 0 {
                    diagnosticRow(
                        label: "Upload Statistics",
                        value: "\(stats.total - stats.failed)/\(stats.total) successful",
                        status: stats.failed == 0 ? .success : (stats.failed < stats.total ? .warning : .failure)
                    )
                    Divider().padding(.leading, 16)
                }

                // Last error
                if let lastError = viewModel.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Last Error")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(formatRelativeTime(lastError.date))
                                .foregroundStyle(.secondary)
                        }
                        Text(lastError.error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    Divider().padding(.leading, 16)
                }

                // No diagnostics message or clear button
                if viewModel.lastConnectionTest == nil && viewModel.lastUpload == nil && viewModel.uploadStats.total == 0 {
                    HStack {
                        Text("No diagnostic data available")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                } else {
                    Button {
                        showClearDiagnosticsConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Diagnostics")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }

    private enum DiagnosticStatus {
        case success, warning, failure
    }

    private func diagnosticRow(label: String, value: String, status: DiagnosticStatus) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 6) {
                Text(value)
                    .foregroundStyle(.secondary)
                statusIcon(for: status)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func statusIcon(for status: DiagnosticStatus) -> some View {
        Group {
            switch status {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .warning:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            case .failure:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
}

#Preview {
    SettingsView()
        .environment(AppState())
}
