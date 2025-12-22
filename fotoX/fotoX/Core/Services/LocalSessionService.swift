//
//  LocalSessionService.swift
//  fotoX
//
//  Local session creation and QR generation
//

import Foundation
import UIKit
import CoreImage.CIFilterBuiltins

@MainActor
final class LocalSessionService: SessionServicing {
    private let galleryBaseURLProvider: @Sendable () -> URL

    init(galleryBaseURLProvider: @escaping @Sendable () -> URL = WorkerConfiguration.currentBaseURL) {
        self.galleryBaseURLProvider = galleryBaseURLProvider
    }

    func createSession(eventId: Int) async throws -> Session {
        let sessionId = UUID().uuidString.uppercased()
        let galleryURL = galleryURLString(for: sessionId)
        return Session(sessionId: sessionId, publicToken: sessionId, universalURL: galleryURL)
    }

    func uploadAsset(
        sessionId: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: AssetUploadMetadata
    ) async throws -> AssetUploadResponse {
        throw APIError.uploadFailed("Upload queue not configured")
    }

    func fetchQRCode(sessionId: String) async throws -> Data {
        let urlString = galleryURLString(for: sessionId)
        guard let qrData = generateQRCode(from: urlString) else {
            throw APIError.invalidResponse
        }
        return qrData
    }

    func submitEmail(sessionId: String, email: String) async throws -> EmailSubmissionResponse {
        return EmailSubmissionResponse(status: "ok")
    }

    private func galleryURLString(for sessionId: String) -> String {
        galleryBaseURLProvider().appendingPathComponent("s").appendingPathComponent(sessionId).absoluteString
    }

    private func generateQRCode(from string: String) -> Data? {
        guard let data = string.data(using: .ascii) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage).pngData()
    }
}
