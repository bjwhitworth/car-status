//
//  VehicleEnquiryError.swift
//  car-status
//
//  Created by GitHub Copilot on 13/07/2025.
//

import Foundation

enum VehicleEnquiryError: Error, LocalizedError, Equatable {
    case invalidRegistration
    case networkError(String)
    case parsingError
    case timeout
    case websiteStructureChanged
    case rateLimited
    case serviceUnavailable
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidRegistration:
            return "Invalid vehicle registration format"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError:
            return "Unable to parse vehicle information"
        case .timeout:
            return "Request timed out. Please try again."
        case .websiteStructureChanged:
            return "Government website has changed. App may need updating."
        case .rateLimited:
            return "Too many requests. Please wait before trying again."
        case .serviceUnavailable:
            return "Government service is currently unavailable"
        case .cancelled:
            return "Request was cancelled"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidRegistration:
            return "Please check the registration number and try again"
        case .networkError:
            return "Check your internet connection and try again"
        case .parsingError, .websiteStructureChanged:
            return "Please update the app or contact support"
        case .timeout, .serviceUnavailable:
            return "Please try again in a few moments"
        case .rateLimited:
            return "Wait a moment before making another request"
        case .cancelled:
            return nil
        }
    }
}
