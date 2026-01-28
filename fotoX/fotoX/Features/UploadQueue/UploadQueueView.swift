//
//  UploadQueueView.swift
//  fotoX
//
//  Upload queue management screen (accessible from Settings)
//

import SwiftUI

struct UploadQueueView: View {
    @State private var viewModel: UploadQueueViewModel

    init(worker: UploadQueueWorker) {
        _viewModel = State(initialValue: UploadQueueViewModel(worker: worker))
    }

    var body: some View {
        List {
            // Active Queue Section
            activeQueueSection

            // Completed History Section
            completedHistorySection
        }
        .navigationTitle("Upload Queue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.hasFailedSessions {
                    Button("Retry All") {
                        Task {
                            await viewModel.retryAllFailed()
                        }
                    }
                    .disabled(viewModel.isRetrying)
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.activeSessions.isEmpty && viewModel.completedRecords.isEmpty {
                ProgressView("Loading queue...")
            }
        }
        .task {
            await viewModel.loadData()
        }
        .task {
            // Poll every 3 seconds while the view is visible
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Active Queue Section

    @ViewBuilder
    private var activeQueueSection: some View {
        Section {
            // Filter control
            if !viewModel.isQueueEmpty {
                Picker("Filter", selection: $viewModel.filter) {
                    Text("All").tag(UploadQueueFilter.all)
                    Text("Failed").tag(UploadQueueFilter.failed)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            if viewModel.filteredSessions.isEmpty && !viewModel.isQueueEmpty {
                // Filter shows no results
                ContentUnavailableView(
                    "No Failed Uploads",
                    systemImage: "checkmark.circle",
                    description: Text("All uploads are in progress or completed")
                )
                .listRowBackground(Color.clear)
            } else if viewModel.isQueueEmpty {
                ContentUnavailableView(
                    "Queue Empty",
                    systemImage: "tray",
                    description: Text("No uploads in progress or pending")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.filteredSessions) { session in
                    activeSessionRow(session: session)
                }
            }
        } header: {
            HStack {
                Text("Active Uploads")
                Spacer()
                if !viewModel.isQueueEmpty {
                    Text("\(viewModel.activeSessions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func activeSessionRow(session: UploadQueueSession) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            statusIcon(for: session.status)
                .frame(width: 28)

            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionId)
                    .font(.subheadline.monospaced())
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(session.progressSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Show elapsed time for uploading sessions
                    if session.status == .uploading, let duration = session.uploadDuration {
                        Text("(\(duration))")
                            .font(.caption2)
                            .foregroundStyle(session.isStale ? Color.red : Color.secondary)
                    }

                    Text(session.createdAt.formattedQueueDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Action menu for all non-complete sessions
            if session.status != .completed {
                if viewModel.retryingSessionId == session.sessionId {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Menu {
                        if session.status == .uploading {
                            Button(role: .destructive) {
                                Task { await viewModel.cancelSession(sessionId: session.sessionId) }
                            } label: {
                                Label("Cancel Upload", systemImage: "xmark.circle")
                            }
                        }
                        
                        Button {
                            Task { await viewModel.forceRetrySession(sessionId: session.sessionId) }
                        } label: {
                            Label(
                                session.status == .uploading ? "Restart Upload" : "Retry Upload",
                                systemImage: "arrow.clockwise"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(session.isStale ? .red : .secondary)
                    }
                    .disabled(viewModel.isRetrying)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Completed History Section

    @ViewBuilder
    private var completedHistorySection: some View {
        Section {
            if viewModel.isHistoryEmpty {
                Text("No completed uploads yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.completedRecords) { record in
                    completedRecordRow(record: record)
                }
            }
        } header: {
            HStack {
                Text("Completed")
                Spacer()
                if !viewModel.isHistoryEmpty {
                    Button("Clear") {
                        Task { await viewModel.clearHistory() }
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func completedRecordRow(record: CompletedUploadRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.sessionId)
                    .font(.subheadline.monospaced())
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(record.assetCount) assets")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(record.completedAt.formattedQueueDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Status Icon

    @ViewBuilder
    private func statusIcon(for status: UploadQueueSessionStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .uploading:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Date Formatting Helper

private extension String {
    /// Formats an ISO8601 date string for queue display
    var formattedQueueDate: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: self) else {
            return self
        }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        UploadQueueView(worker: UploadQueueWorker())
    }
}
