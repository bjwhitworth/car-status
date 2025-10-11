//
//  VehicleEnquiryService.swift
//  car-status
//
//  Created by GitHub Copilot on 13/07/2025.
//

import Foundation
import WebKit
import Combine

protocol VehicleEnquiryServiceProtocol {
    func checkVehicleStatus(registration: String) -> AnyPublisher<VehicleStatus, VehicleEnquiryError>
    func cancelCurrentRequest()
}

final class VehicleEnquiryService: NSObject, VehicleEnquiryServiceProtocol, WKNavigationDelegate {
    private let webView: WKWebView
    private var currentSubject: PassthroughSubject<VehicleStatus, VehicleEnquiryError>?
    private var timeoutTimer: Timer?
    private var retryCount = 0
    private let maxRetries = 3
    private let requestTimeout: TimeInterval = 30.0
    private var lastRequestTime: Date?
    private let rateLimitInterval: TimeInterval = 2.0
    private var currentRegistration: String?
    private var isReady = false
    
    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        // Configure for better reliability
        configuration.processPool = WKProcessPool()
        
        // Remove deprecated javaScriptEnabled setting
        // JavaScript will be enabled by default and we'll control it per-navigation if needed
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        
        // Give WebView time to initialize properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isReady = true
            print("✅ VehicleEnquiryService is ready")
        }
    }
    
    func checkVehicleStatus(registration: String) -> AnyPublisher<VehicleStatus, VehicleEnquiryError> {
        print("🔍 CheckVehicleStatus called for: \(registration), isReady: \(isReady)")
        
        // Check if service is ready
        guard isReady else {
            print("⏳ Service not ready, delaying request...")
            return Fail(error: VehicleEnquiryError.serviceUnavailable)
                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                .flatMap { (_: Void) in
                    self.checkVehicleStatus(registration: registration)
                }
                .eraseToAnyPublisher()
        }
        
        // Check rate limiting
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < rateLimitInterval {
            return Fail(error: VehicleEnquiryError.rateLimited)
                .eraseToAnyPublisher()
        }
        
        // Validate registration format
        guard isValidUKRegistration(registration) else {
            return Fail(error: VehicleEnquiryError.invalidRegistration)
                .eraseToAnyPublisher()
        }
        
        // Cancel any existing request
        cancelCurrentRequest()
        
        let subject = PassthroughSubject<VehicleStatus, VehicleEnquiryError>()
        currentSubject = subject
        currentRegistration = registration
        lastRequestTime = Date()
        retryCount = 0
        
        startRequest(registration: registration, subject: subject)
        
        return subject
            .timeout(.seconds(requestTimeout), scheduler: DispatchQueue.main, customError: {
                VehicleEnquiryError.timeout
            })
            .eraseToAnyPublisher()
    }
    
    func cancelCurrentRequest() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        webView.stopLoading()
        currentSubject?.send(completion: .failure(.cancelled))
        currentSubject = nil
    }
    
    private func startRequest(registration: String, subject: PassthroughSubject<VehicleStatus, VehicleEnquiryError>) {
        let url = URL(string: "https://vehicleenquiry.service.gov.uk/?locale=en")!
        let request = URLRequest(url: url)
        webView.load(request)
        
        // Set timeout
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: requestTimeout, repeats: false) { [weak self] _ in
            self?.handleTimeout(registration: registration, subject: subject)
        }
        
        // Submit form after page loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.submitForm(registration: registration, subject: subject)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        // Enable JavaScript for all navigations (this is the modern way)
        preferences.allowsContentJavaScript = true
        decisionHandler(.allow, preferences)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let subject = currentSubject else { return }
        
        let currentURL = webView.url?.absoluteString ?? ""
        
        if currentURL.contains("ConfirmVehicle") {
            handleConfirmationPage(subject: subject)
        } else if currentURL.contains("VehicleFound") {
            extractVehicleData(subject: subject)
        } else if currentURL.contains("VehicleNotFound") {
            handleError(.invalidRegistration, subject: subject)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let subject = currentSubject else { return }
        
        // Check if this is a network-related error that we should retry
        if retryCount < maxRetries && isNetworkError(error) {
            retryCount += 1
            let delay = min(pow(2.0, Double(retryCount)), 5.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, let registration = self.currentRegistration else { return }
                self.startRequest(registration: registration, subject: subject)
            }
        } else {
            handleError(.networkError(error.localizedDescription), subject: subject)
        }
    }
    
    private func submitForm(registration: String, subject: PassthroughSubject<VehicleStatus, VehicleEnquiryError>) {
        let script = """
        (function() {
            try {
                const input = document.getElementById('wizard_vehicle_enquiry_capture_vrn_vrn');
                const submit = document.getElementById('submit_vrn_button');
                
                if (!input || !submit) {
                    return { success: false, error: 'Form elements not found' };
                }
                
                input.value = "\(registration)";
                input.dispatchEvent(new Event('input', { bubbles: true }));
                submit.click();
                
                return { success: true };
            } catch (error) {
                return { success: false, error: error.message };
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { [weak self] (result: Any?, error: Error?) in
            if let error = error {
                self?.handleError(.networkError(error.localizedDescription), subject: subject)
            } else if let result = result as? [String: Any],
                      let success = result["success"] as? Bool,
                      !success {
                _ = result["error"] as? String ?? "Unknown error"
                self?.handleError(.parsingError, subject: subject)
            }
        }
    }
    
    private func handleTimeout(registration: String, subject: PassthroughSubject<VehicleStatus, VehicleEnquiryError>) {
        if retryCount < maxRetries {
            retryCount += 1
            let delay = min(pow(2.0, Double(retryCount)), 8.0) // Cap at 8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.startRequest(registration: registration, subject: subject)
            }
        } else {
            handleError(.timeout, subject: subject)
        }
    }
    
    private func handleError(_ error: VehicleEnquiryError, subject: PassthroughSubject<VehicleStatus, VehicleEnquiryError>) {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        subject.send(completion: .failure(error))
        currentSubject = nil
    }
    
    private func isValidUKRegistration(_ registration: String) -> Bool {
        let cleaned = registration.replacingOccurrences(of: " ", with: "").uppercased()
        
        // Basic UK registration patterns
        let patterns = [
            "^[A-Z]{2}[0-9]{2}[A-Z]{3}$", // Current format: AB12 CDE
            "^[A-Z][0-9]{1,3}[A-Z]{3}$",  // Prefix format: A123 BCD
            "^[A-Z]{3}[0-9]{1,3}[A-Z]$",  // Suffix format: ABC 123D
            "^[0-9]{1,4}[A-Z]{1,3}$"      // Old format: 1234 AB
        ]
        
        return patterns.contains { pattern in
            cleaned.range(of: pattern, options: .regularExpression) != nil
        }
    }
    
    private func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost
        ].contains(nsError.code)
    }
    
    private func handleConfirmationPage(subject: PassthroughSubject<VehicleStatus, VehicleEnquiryError>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let confirmScript = """
            (function() {
                try {
                    let yesButton = document.getElementById('yes-vehicle-confirm');
                    let confirmButton = document.getElementById('capture_confirm_button');
                    
                    if (yesButton) {
                        yesButton.click();
                        if (confirmButton) {
                            setTimeout(() => confirmButton.click(), 500);
                        }
                        return { success: true };
                    }
                    return { success: false, error: 'Confirmation buttons not found' };
                } catch (error) {
                    return { success: false, error: error.message };
                }
            })();
            """
            
            self?.webView.evaluateJavaScript(confirmScript) { result, error in
                if let error = error {
                    self?.handleError(.networkError(error.localizedDescription), subject: subject)
                }
            }
        }
    }
    
    private func extractVehicleData(subject: PassthroughSubject<VehicleStatus, VehicleEnquiryError>) {
        let extractionScript = """
        (function() {
            try {
                // Get tax status and due date
                let taxPanel = document.querySelector('.govuk-grid-column-one-half .govuk-panel__title span[aria-hidden="true"]');
                let taxStatus = taxPanel ? taxPanel.textContent.replace(/\\n/g, ' ').trim() : '';
                let taxDueElement = document.querySelector('.govuk-grid-column-one-half .govuk-panel__body strong');
                let taxDueDate = taxDueElement ? taxDueElement.textContent.trim() : '';
                
                // Get MOT status and expiry date
                let motPanel = document.querySelector('#mot-status-panel .govuk-panel__title span[aria-hidden="true"]');
                let motStatus = motPanel ? motPanel.textContent.replace(/\\n/g, ' ').trim() : '';
                let motExpiryElement = document.querySelector('#mot-status-panel .govuk-panel__body strong');
                let motExpiryDate = motExpiryElement ? motExpiryElement.textContent.trim() : '';
                
                return {
                    success: true,
                    data: {
                        taxStatus: taxStatus,
                        taxDueDate: taxDueDate,
                        motStatus: motStatus,
                        motExpiryDate: motExpiryDate
                    }
                };
            } catch (error) {
                return { success: false, error: error.message };
            }
        })();
        """
        
        webView.evaluateJavaScript(extractionScript) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleError(.networkError(error.localizedDescription), subject: subject)
                return
            }
            
            guard let resultDict = result as? [String: Any],
                  let success = resultDict["success"] as? Bool,
                  success,
                  let data = resultDict["data"] as? [String: String] else {
                self.handleError(.parsingError, subject: subject)
                return
            }
            
            // Create vehicle status
            let taxInfo = TaxInfo(
                status: data["taxStatus"] ?? "",
                dueDate: data["taxDueDate"]?.isEmpty == false ? data["taxDueDate"] : nil
            )
            
            let motInfo = MOTInfo(
                status: data["motStatus"] ?? "",
                expiryDate: data["motExpiryDate"]?.isEmpty == false ? data["motExpiryDate"] : nil
            )
            
            guard let registration = self.currentRegistration else { return }
            
            let vehicleStatus = VehicleStatus(
                registration: registration,
                taxInfo: taxInfo,
                motInfo: motInfo,
                lastChecked: Date()
            )
            
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil
            subject.send(vehicleStatus)
            subject.send(completion: .finished)
            self.currentSubject = nil
            self.currentRegistration = nil
        }
    }
}
