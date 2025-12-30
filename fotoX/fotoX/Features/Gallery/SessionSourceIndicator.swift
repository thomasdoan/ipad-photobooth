//
//  SessionSourceIndicator.swift
//  fotoX
//
//  Reusable session source indicator component
//

import SwiftUI

/// Visual indicator showing where a session's data comes from
struct SessionSourceIndicator: View {
    let source: SessionSource
    var style: Style = .compact

    enum Style {
        case compact    // Icon only
        case labeled    // Icon with text label
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(iconFont)

            if case .labeled = style {
                Text(labelText)
                    .font(labelFont)
            }
        }
        .foregroundStyle(sourceColor)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(sourceColor.opacity(0.2))
        .clipShape(Capsule())
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch source {
        case .local: return "ipad"
        case .remote: return "cloud"
        case .both: return "checkmark.icloud"
        }
    }

    private var sourceColor: Color {
        switch source {
        case .local: return .orange
        case .remote: return .blue
        case .both: return .green
        }
    }

    private var labelText: String {
        switch source {
        case .local: return "Local"
        case .remote: return "Uploaded"
        case .both: return "Synced"
        }
    }

    private var iconFont: Font {
        switch style {
        case .compact: return .caption
        case .labeled: return .caption2
        }
    }

    private var labelFont: Font {
        .caption2
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .compact: return 10
        case .labeled: return 8
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .compact: return 6
        case .labeled: return 4
        }
    }
}

// MARK: - Previews

#Preview("Compact Style") {
    VStack(spacing: 16) {
        SessionSourceIndicator(source: .local, style: .compact)
        SessionSourceIndicator(source: .remote, style: .compact)
        SessionSourceIndicator(source: .both, style: .compact)
    }
    .padding()
    .background(Color.black)
}

#Preview("Labeled Style") {
    VStack(spacing: 16) {
        SessionSourceIndicator(source: .local, style: .labeled)
        SessionSourceIndicator(source: .remote, style: .labeled)
        SessionSourceIndicator(source: .both, style: .labeled)
    }
    .padding()
    .background(Color.black)
}
