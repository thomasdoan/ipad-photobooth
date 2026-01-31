//
//  QRCodeGenerator.swift
//  fotoX
//
//  Reusable QR code generation utility
//

import Foundation
import UIKit
import CoreImage.CIFilterBuiltins

/// Utility for generating QR codes
enum QRCodeGenerator {
    /// Generates a QR code image from a string
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - scale: The scale factor for the QR code (default 10)
    /// - Returns: A UIImage of the QR code, or nil if generation fails
    static func generate(from string: String, scale: CGFloat = 10) -> UIImage? {
        guard let data = string.data(using: .ascii) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    /// Generates QR code PNG data from a string
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - scale: The scale factor for the QR code (default 10)
    /// - Returns: PNG data of the QR code, or nil if generation fails
    static func generateData(from string: String, scale: CGFloat = 10) -> Data? {
        generate(from: string, scale: scale)?.pngData()
    }
    
    /// Generates a gallery URL for a session
    /// - Parameter sessionId: The session ID
    /// - Returns: The full gallery URL string
    static func galleryURL(for sessionId: String) -> String {
        WorkerConfiguration.currentBaseURL()
            .appendingPathComponent("session")
            .appendingPathComponent(sessionId)
            .absoluteString
    }
    
    /// Generates a gallery URL from a gallery path
    /// - Parameter galleryPath: The gallery path (e.g., "session/{sessionId}")
    /// - Returns: The full gallery URL string
    static func galleryURL(from galleryPath: String) -> String {
        WorkerConfiguration.currentBaseURL()
            .appendingPathComponent(galleryPath)
            .absoluteString
    }
}
