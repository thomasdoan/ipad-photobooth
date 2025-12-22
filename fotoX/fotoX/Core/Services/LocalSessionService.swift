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
    private let galleryBaseURL: URL

    init(galleryBaseURL: URL) {
        self.galleryBaseURL = galleryBaseURL
    }

    func createSession(eventId: Int) async throws -> Session {
        let sessionId = Int.random(in: 1000...9999)
        let galleryURL = galleryURLString(for: sessionId)
        return Session(sessionId: sessionId, publicToken: String(sessionId), universalURL: galleryURL)
    }

    func uploadAsset(
        sessionId: Int,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: AssetUploadMetadata
    ) async throws -> AssetUploadResponse {
        throw APIError.uploadFailed("Upload queue not configured")
    }

    func fetchQRCode(sessionId: Int) async throws -> Data {
        let urlString = galleryURLString(for: sessionId)
        guard let qrData = generateQRCode(from: urlString) else {
            throw APIError.invalidResponse
        }
        return qrData
    }

    func submitEmail(sessionId: Int, email: String) async throws -> EmailSubmissionResponse {
        return EmailSubmissionResponse(status: "ok")
    }

    private func galleryURLString(for sessionId: Int) -> String {
        galleryBaseURL.appendingPathComponent("s").appendingPathComponent(String(sessionId)).absoluteString
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
