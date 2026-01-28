//
//  FrameSelectorView.swift
//  fotoX
//
//  Frame picker for strip summary review
//

import SwiftUI

@MainActor
struct FrameSelectorView: View {
    let frames: [FrameOption]
    @Binding var selectedFrame: String?

    let strips: [CapturedStrip]
    let slotAspectRatio: CGFloat
    let footerText: String

    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    
    @State private var compositePreviewByFrameName: [String: Data] = [:]

    init(
        frames: [FrameOption] = FrameOption.availableFrames,
        selectedFrame: Binding<String?>,
        strips: [CapturedStrip],
        slotAspectRatio: CGFloat,
        footerText: String
    ) {
        self.frames = frames
        self._selectedFrame = selectedFrame
        self.strips = strips
        self.slotAspectRatio = slotAspectRatio
        self.footerText = footerText
    }

    var body: some View {
        let usableFrames = frames.filter { $0.loadFrameImage() != nil }
        let columns = [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14),
        ]

        VStack(alignment: .leading, spacing: 12) {
            Text("Frame")
                .font(.headline)
                .foregroundStyle(theme.accent)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(usableFrames) { option in
                        frameButton(option: option)
                    }
                }
                .padding(.vertical, 2)
                .padding(.trailing, 6) // leave room for scroll indicator
            }
        }
    }

    @ViewBuilder
    private func frameButton(option: FrameOption) -> some View {
        let isSelected = selectedFrame == option.frameName
        let previewSize = CGSize(width: 260, height: 364)

        Button {
            selectedFrame = option.frameName
        } label: {
            VStack(spacing: 16) {
                compositePhotoPreview(option: option, size: previewSize)

                Text(option.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? theme.primary : theme.accent.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("frameOption.\(option.id)")
        .task(id: option.frameName) {
            await ensureCompositePreview(for: option)
        }
    }

    @ViewBuilder
    private func compositePhotoPreview(option: FrameOption, size: CGSize) -> some View {
        let isSelected = selectedFrame == option.frameName

        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.secondary.opacity(0.25))
            if let data = compositePreviewByFrameName[option.frameName],
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(14) // Add padding between background and image ("the frame")
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? theme.primary : theme.accent.opacity(0.2), lineWidth: isSelected ? 3 : 1)
        )
    }

    private func ensureCompositePreview(for option: FrameOption) async {
        if compositePreviewByFrameName[option.frameName] != nil {
            return
        }

        // If the frame cannot be loaded, skip rendering.
        guard option.loadFrameImage() != nil else { return }

        do {
            let data = try StripCompositeRenderer.renderCompositePhotoData(
                strips: strips,
                theme: theme,
                assets: themeAssets,
                footerText: footerText,
                customFrameAssetName: option.frameName,
                slotAspectRatio: slotAspectRatio
            )
            compositePreviewByFrameName[option.frameName] = data
        } catch {
            // Leave placeholder; don't crash frame picker for preview failures.
        }
    }
}

