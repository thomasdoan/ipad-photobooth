//
//  StripPreviewView.swift
//  fotoX
//
//  Simulator helper for previewing strip frame layout
//

import SwiftUI

@MainActor
struct StripPreviewView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedKind: AssetKind = .photo

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 24) {
                    Picker("Strip Type", selection: $selectedKind) {
                        Text("Photo").tag(AssetKind.photo)
                        Text("Video").tag(AssetKind.video)
                    }
                    .pickerStyle(.segmented)

                    StripCompositeView(
                        slots: stripSlots(),
                        footerText: stripFooterText(),
                        slotAspectRatio: stripAspectRatio
                    ) { slot in
                        previewSlot(slot: slot)
                    }
                    .frame(width: stripSize(for: geometry).width, height: stripSize(for: geometry).height)

                    VStack(spacing: 6) {
                        Text("Frame: \(frameSource)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Footer: \(stripFooterText())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
            }
            .navigationTitle("Strip Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var stripAspectRatio: CGFloat {
        appState.resolvedCaptureAspectRatio.widthToHeight
    }

    private func stripSlots() -> [StripSlot] {
        (0..<3).map { StripSlot(id: $0, isVideo: selectedKind == .video) }
    }

    private func stripFooterText() -> String {
        theme.stripFooterText ?? appState.selectedEvent?.name ?? "FotoX"
    }

    private func stripSize(for geometry: GeometryProxy) -> CGSize {
        StripCompositeMetrics.sizeThatFits(
            maxWidth: min(geometry.size.width * 0.7, 360),
            maxHeight: geometry.size.height * 0.7,
            slotCount: 3,
            slotAspectRatio: stripAspectRatio
        )
    }

    private var frameSource: String {
        if let assetName = theme.stripFrameAssetName, !assetName.isEmpty {
            return "asset:\(assetName)"
        }
        if let url = theme.stripFrameURL {
            return url.absoluteString
        }
        return "default"
    }

    private func previewSlot(slot: StripSlot) -> some View {
        let colors = [
            theme.primary.opacity(0.9),
            theme.accent.opacity(0.8),
            theme.primary.opacity(0.7)
        ]
        let start = colors[slot.id % colors.count]
        let end = colors[(slot.id + 1) % colors.count]

        return ZStack {
            LinearGradient(
                colors: [start, end],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text("\(slot.id + 1)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

#Preview {
    StripPreviewView()
        .environment(AppState())
        .withTheme(.default)
}
