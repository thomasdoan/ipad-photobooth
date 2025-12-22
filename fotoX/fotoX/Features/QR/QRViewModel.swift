//
//  QRViewModel.swift
//  fotoX
//
//  ViewModel for the QR code and email screen
//

import Foundation
import UIKit
import Observation

/// ViewModel for QR display and email submission
@Observable
final class QRViewModel<SessionService: SessionServicing> {
    // MARK: - State
    
    /// QR code image
    var qrImage: UIImage?
    
    /// Universal URL for the session
    var universalURL: String = ""
    
    /// Email input
    var email: String = ""
    
    /// Whether email is being submitted
    var isSubmittingEmail: Bool = false
    
    /// Whether email was submitted successfully
    var emailSubmitted: Bool = false
    
    /// Email validation error
    var emailError: String?
    
    /// General error message
    var errorMessage: String?
    
    /// Whether QR is loading
    var isLoadingQR: Bool = false
    
    // MARK: - Dependencies
    
    private let sessionService: SessionService
    private let testableServices: TestableServiceContainer?
    
    // MARK: - Initialization
    
    init(sessionService: SessionService, testableServices: TestableServiceContainer? = nil) {
        self.sessionService = sessionService
        self.testableServices = testableServices
    }
    
    // MARK: - Setup
    
    /// Sets up the view model with session data
    @MainActor
    func setup(qrData: Data?, session: Session?) {
        if let session = session {
            universalURL = session.universalURL
        }
        
        if let qrData = qrData, !qrData.isEmpty {
            qrImage = UIImage(data: qrData)
        }
    }
    
    /// Fetches QR code if not already loaded
    @MainActor
    func fetchQRIfNeeded(sessionId: Int) async {
        guard qrImage == nil else { return }
        
        isLoadingQR = true
        
        do {
            let data: Data
            if let testable = testableServices {
                data = try await testable.fetchQRCode(sessionId: sessionId)
            } else {
                data = try await sessionService.fetchQRCode(sessionId: sessionId)
            }
            qrImage = UIImage(data: data)
        } catch let error as APIError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to load QR code"
        }
        
        isLoadingQR = false
    }
    
    // MARK: - Email
    
    /// Validates email format
    var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    /// Submits the email
    @MainActor
    func submitEmail(sessionId: Int) async {
        // Validate email
        guard !email.isEmpty else {
            emailError = "Please enter your email"
            return
        }
        
        guard isEmailValid else {
            emailError = "Please enter a valid email address"
            return
        }
        
        emailError = nil
        isSubmittingEmail = true
        
        do {
            if let testable = testableServices {
                _ = try await testable.submitEmail(sessionId: sessionId, email: email)
            } else {
                _ = try await sessionService.submitEmail(sessionId: sessionId, email: email)
            }
            emailSubmitted = true
        } catch let error as APIError {
            emailError = error.userMessage
        } catch {
            emailError = "Failed to submit email"
        }
        
        isSubmittingEmail = false
    }
    
    /// Clears the email error
    func clearEmailError() {
        emailError = nil
    }
}
