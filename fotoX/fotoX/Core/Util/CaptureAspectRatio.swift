//
//  CaptureAspectRatio.swift
//  fotoX
//
//  Capture aspect ratio settings and resolution helpers
//

import CoreGraphics
import Foundation

enum LayoutOrientation: String, Sendable {
    case portrait
    case landscape
}

enum CaptureAspectRatio: String, CaseIterable, Identifiable, Sendable {
    case auto
    case ratio9x16
    case ratio16x9
    case ratio4x3

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto:
            return "Auto"
        case .ratio9x16:
            return "9:16"
        case .ratio16x9:
            return "16:9"
        case .ratio4x3:
            return "4:3"
        }
    }

    var detailLabel: String {
        switch self {
        case .auto:
            return "Portrait 9:16, Landscape 16:9"
        case .ratio9x16:
            return "Portrait"
        case .ratio16x9:
            return "Landscape"
        case .ratio4x3:
            return "Classic photo"
        }
    }

    func resolved(for orientation: LayoutOrientation) -> CaptureAspectRatio {
        switch self {
        case .auto:
            return orientation == .landscape ? .ratio16x9 : .ratio9x16
        case .ratio9x16, .ratio16x9, .ratio4x3:
            return self
        }
    }

    func resolvedWidthToHeight(for orientation: LayoutOrientation) -> CGFloat {
        resolved(for: orientation).widthToHeight
    }

    var widthToHeight: CGFloat {
        switch self {
        case .auto:
            return 9.0 / 16.0
        case .ratio9x16:
            return 9.0 / 16.0
        case .ratio16x9:
            return 16.0 / 9.0
        case .ratio4x3:
            return 4.0 / 3.0
        }
    }

    var preferredOrientation: LayoutOrientation {
        widthToHeight >= 1 ? .landscape : .portrait
    }
}
