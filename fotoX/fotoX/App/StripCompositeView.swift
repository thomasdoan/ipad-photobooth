//
//  StripCompositeView.swift
//  fotoX
//
//  Composite strip layout for photo/video previews with themed frame
//

import SwiftUI

struct StripSlot: Identifiable, Hashable {
    let id: Int
    let isVideo: Bool
}

enum StripCompositeMetrics {
    static let slotAspectRatio: CGFloat = 9.0 / 16.0
    static let spacingRatio: CGFloat = 0.08
    static let footerHeightRatio: CGFloat = 0.45
    static let horizontalPaddingRatio: CGFloat = 0.08
    static let verticalPaddingRatio: CGFloat = 0.08

    static func height(forWidth width: CGFloat, slotCount: Int = 3) -> CGFloat {
        let slots = max(slotCount, 1)
        let slotWidth = width / (1 + 2 * horizontalPaddingRatio)
        let slotHeight = slotWidth / slotAspectRatio
        let spacing = slotWidth * spacingRatio
        let footerHeight = slotWidth * footerHeightRatio
        let verticalPadding = slotWidth * verticalPaddingRatio
        return slotHeight * CGFloat(slots)
            + spacing * CGFloat(slots - 1)
            + footerHeight
            + verticalPadding * 2
    }

    static func width(forHeight height: CGFloat, slotCount: Int = 3) -> CGFloat {
        let slots = max(slotCount, 1)
        let slotHeightRatio = 1 / slotAspectRatio
        let heightRatio = slotHeightRatio * CGFloat(slots)
            + spacingRatio * CGFloat(slots - 1)
            + footerHeightRatio
            + verticalPaddingRatio * 2
        let slotWidth = height / heightRatio
        return slotWidth * (1 + 2 * horizontalPaddingRatio)
    }

    static func sizeThatFits(maxWidth: CGFloat, maxHeight: CGFloat, slotCount: Int = 3) -> CGSize {
        let widthByHeight = width(forHeight: maxHeight, slotCount: slotCount)
        let width = min(maxWidth, widthByHeight)
        let height = height(forWidth: width, slotCount: slotCount)
        return CGSize(width: width, height: height)
    }
}

struct StripCompositeView<SlotContent: View>: View {
    let slots: [StripSlot]
    let footerText: String
    let slotContent: (StripSlot) -> SlotContent

    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { geometry in
            let layout = StripCompositeLayout(
                availableSize: geometry.size,
                slotCount: slots.count
            )

            ThemedStripFrame(cornerRadius: layout.outerCornerRadius) {
                VStack(spacing: layout.slotSpacing) {
                    ForEach(slots) { slot in
                        ZStack {
                            slotContent(slot)
                                .frame(width: layout.slotWidth, height: layout.slotHeight)
                                .clipped()

                            if slot.isVideo {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: layout.slotWidth * 0.18))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.4), radius: 6)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(theme.secondary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: layout.slotCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: layout.slotCornerRadius, style: .continuous)
                                .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                        )
                    }

                    stripFooter(height: layout.footerHeight)
                }
                .padding(.horizontal, layout.horizontalPadding)
                .padding(.vertical, layout.verticalPadding)
                .frame(width: layout.totalWidth, height: layout.totalHeight)
                .background(theme.secondary.opacity(0.9))
            }
            .frame(width: layout.totalWidth, height: layout.totalHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private func stripFooter(height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
                .fill(theme.secondary.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
                        .stroke(theme.primary.opacity(0.4), lineWidth: 1)
                )

            Text(footerText)
                .font(footerFont(size: height * 0.3))
                .foregroundStyle(theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, height * 0.3)
        }
        .frame(height: height)
    }

    private func footerFont(size: CGFloat) -> Font {
        if theme.fontFamily == "system" {
            return .system(size: size, weight: .semibold, design: .rounded)
        }
        return .custom(theme.fontFamily, size: size)
    }
}

private struct StripCompositeLayout {
    let slotWidth: CGFloat
    let slotHeight: CGFloat
    let slotSpacing: CGFloat
    let footerHeight: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let totalWidth: CGFloat
    let totalHeight: CGFloat
    let slotCornerRadius: CGFloat
    let outerCornerRadius: CGFloat

    init(availableSize: CGSize, slotCount: Int) {
        let slots = max(slotCount, 1)
        let widthLimit = max(availableSize.width, 1)
        let heightLimit = max(availableSize.height, 1)

        let widthByHeight = StripCompositeMetrics.width(forHeight: heightLimit, slotCount: slots)
        let totalWidth = min(widthLimit, widthByHeight)

        let slotWidth = totalWidth / (1 + 2 * StripCompositeMetrics.horizontalPaddingRatio)
        let slotHeight = slotWidth / StripCompositeMetrics.slotAspectRatio
        let slotSpacing = slotWidth * StripCompositeMetrics.spacingRatio
        let footerHeight = slotWidth * StripCompositeMetrics.footerHeightRatio
        let horizontalPadding = slotWidth * StripCompositeMetrics.horizontalPaddingRatio
        let verticalPadding = slotWidth * StripCompositeMetrics.verticalPaddingRatio
        let totalHeight = slotHeight * CGFloat(slots)
            + slotSpacing * CGFloat(slots - 1)
            + footerHeight
            + verticalPadding * 2

        self.slotWidth = slotWidth
        self.slotHeight = slotHeight
        self.slotSpacing = slotSpacing
        self.footerHeight = footerHeight
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.totalWidth = totalWidth
        self.totalHeight = totalHeight
        self.slotCornerRadius = slotWidth * 0.08
        self.outerCornerRadius = slotWidth * 0.12
    }
}
