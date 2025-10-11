//
//  VehicleStatus.swift
//  car-status
//
//  Created by GitHub Copilot on 13/07/2025.
//

import Foundation

struct VehicleStatus: Codable, Equatable {
    let registration: String
    let taxInfo: TaxInfo
    let motInfo: MOTInfo
    let lastChecked: Date
    
    var isValid: Bool {
        taxInfo.isValid && motInfo.isValid
    }
}

struct TaxInfo: Codable, Equatable {
    let status: String
    let dueDate: String?
    let isValid: Bool
    
    init(status: String, dueDate: String? = nil) {
        self.status = status
        self.dueDate = dueDate
        self.isValid = status.lowercased().contains("✓") && status.lowercased().contains("taxed")
    }
}

struct MOTInfo: Codable, Equatable {
    let status: String
    let expiryDate: String?
    let isValid: Bool
    
    init(status: String, expiryDate: String? = nil) {
        self.status = status
        self.expiryDate = expiryDate
        self.isValid = status.lowercased().contains("✓") && status.lowercased().contains("mot")
    }
}
