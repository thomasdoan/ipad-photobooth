//
//  QRCodeDisplayView.swift
//  fotoX
//
//  Reusable QR code display component
//

import SwiftUI

/// Configuration for QR code display appearance
struct QRCodeDisplayConfig {
    /// Maximum size of the QR code
    var maxSize: CGFloat = 280
    /// Padding around the QR code inside the white background
    var padding: CGFloat = 24
    /// Corner radius of the white background
    var cornerRadius: CGFloat = 24
    /// Shadow radius
    var shadowRadius: CGFloat = 20
    /// Shadow Y offset
    var shadowY: CGFloat = 10
    /// Shadow opacity
    var shadowOpacity: CGFloat = 0.3
    
    static let `default` = QRCodeDisplayConfig()
    
    /// Compact config for smaller displays
    static let compact = QRCodeDisplayConfig(
        maxSize: 180,
        padding: 16,
        cornerRadius: 20,
        shadowRadius: 12,
        shadowY: 6,
        shadowOpacity: 0.15
    )
}

/// Reusable QR code display view with loading and error states
struct QRCodeDisplayView: View {
    /// The QR code image to display (if already generated)
    let qrImage: UIImage?
    /// Whether the QR code is loading
    let isLoading: Bool
    /// Optional retry action for error state
    let onRetry: (() -> Void)?
    /// Display configuration
    let config: QRCodeDisplayConfig
    /// Accent color for retry button
    let accentColor: Color
    
    init(
        qrImage: UIImage?,
        isLoading: Bool = false,
        config: QRCodeDisplayConfig = .default,
        accentColor: Color = .blue,
        onRetry: (() -> Void)? = nil
    ) {
        self.qrImage = qrImage
        self.isLoading = isLoading
        self.config = config
        self.accentColor = accentColor
        self.onRetry = onRetry
    }
    
    /// Convenience initializer for generating QR from URL string
    init(
        urlString: String,
        config: QRCodeDisplayConfig = .default,
        accentColor: Color = .blue
    ) {
        self.qrImage = QRCodeGenerator.generate(from: urlString)
        self.isLoading = false
        self.config = config
        self.accentColor = accentColor
        self.onRetry = nil
    }
    
    var body: some View {
        Group {
            if let qrImage {
                // Success: Show QR code
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: config.maxSize, maxHeight: config.maxSize)
                    .padding(config.padding)
                    .background(
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .fill(.white)
                    )
                    .shadow(
                        color: .black.opacity(config.shadowOpacity),
                        radius: config.shadowRadius,
                        y: config.shadowY
                    )
            } else if isLoading {
                // Loading state
                ZStack {
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .fill(.white)
                        .frame(
                            width: config.maxSize + config.padding * 2,
                            height: config.maxSize + config.padding * 2
                        )
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                        .scaleEffect(1.2)
                }
                .shadow(
                    color: .black.opacity(config.shadowOpacity),
                    radius: config.shadowRadius,
                    y: config.shadowY
                )
            } else {
                // Error state
                ZStack {
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .fill(.white)
                        .frame(
                            width: config.maxSize + config.padding * 2,
                            height: config.maxSize + config.padding * 2
                        )
                    
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        
                        Text("QR code unavailable")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        if let onRetry {
                            Button("Retry", action: onRetry)
                                .font(.caption.bold())
                                .foregroundStyle(accentColor)
                        }
                    }
                }
                .shadow(
                    color: .black.opacity(config.shadowOpacity),
                    radius: config.shadowRadius,
                    y: config.shadowY
                )
            }
        }
    }
}

/// URL display section that accompanies QR codes
struct QRCodeURLView: View {
    let urlString: String
    let labelColor: Color
    let urlColor: Color
    let backgroundColor: Color
    
    init(
        urlString: String,
        labelColor: Color = .white.opacity(0.5),
        urlColor: Color = .white.opacity(0.8),
        backgroundColor: Color = .white.opacity(0.1)
    ) {
        self.urlString = urlString
        self.labelColor = labelColor
        self.urlColor = urlColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Or visit:")
                .font(.caption)
                .foregroundStyle(labelColor)
            
            Text(urlString)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(urlColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                )
        }
    }
}

#Preview("QR Code - Success") {
    ZStack {
        Color.black.ignoresSafeArea()
        QRCodeDisplayView(urlString: "https://example.com/s/test-session")
    }
}

#Preview("QR Code - Loading") {
    ZStack {
        Color.black.ignoresSafeArea()
        QRCodeDisplayView(qrImage: nil, isLoading: true)
    }
}

#Preview("QR Code - Error with Retry") {
    ZStack {
        Color.black.ignoresSafeArea()
        QRCodeDisplayView(qrImage: nil, isLoading: false) {
            print("Retry tapped")
        }
    }
}

#Preview("QR Code - Compact") {
    ZStack {
        Color.black.ignoresSafeArea()
        QRCodeDisplayView(
            urlString: "https://example.com/s/test-session",
            config: .compact
        )
    }
}
