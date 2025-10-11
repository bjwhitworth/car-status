//
//  VehicleStatusViewModel.swift
//  car-status
//
//  Created by GitHub Copilot on 13/07/2025.
//

import Foundation
import Combine
import SwiftUI

final class VehicleStatusViewModel: ObservableObject {
    @Published var vehicleStatus: VehicleStatus?
    @Published var isLoading = false
    @Published var carRegistration = ""
    @Published var errorMessage: String?
    @Published var lastChecked: Date?
    
    private let enquiryService: VehicleEnquiryServiceProtocol
    private let repository: VehicleRepositoryProtocol
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialized = false
    private var pendingAutoRefresh = false
    
    init(
        enquiryService: VehicleEnquiryServiceProtocol = VehicleEnquiryService(),
        repository: VehicleRepositoryProtocol = VehicleRepository(),
        networkMonitor: NetworkMonitor = NetworkMonitor()
    ) {
        self.enquiryService = enquiryService
        self.repository = repository
        self.networkMonitor = networkMonitor
        
        setupNetworkMonitoring()
        loadSavedData()
        
        // Mark as initialized and check for auto-refresh after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hasInitialized = true
            self.checkForAutoRefresh()
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .dropFirst(2) // Ignore the first few values to avoid false negatives during initialization
            .sink { [weak self] isConnected in
                if !isConnected && self?.isLoading == true {
                    self?.errorMessage = "Connection lost during request"
                    self?.isLoading = false
                }
                
                // If network becomes available and we have a pending auto-refresh, execute it
                if isConnected && self?.pendingAutoRefresh == true && self?.hasInitialized == true {
                    self?.performAutoRefresh()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSavedData() {
        print("📱 Loading saved data...")
        if let savedRegistration = repository.getSavedRegistration() {
            print("💾 Found saved registration: \(savedRegistration)")
            carRegistration = savedRegistration
            
            // Load cached data if available
            if let cachedStatus = repository.loadVehicleStatus(for: savedRegistration) {
                print("📋 Found cached data from: \(cachedStatus.lastChecked)")
                vehicleStatus = cachedStatus
                lastChecked = cachedStatus.lastChecked
                
                // Check if data needs refreshing (older than 1 hour)
                let timeSinceLastCheck = Date().timeIntervalSince(cachedStatus.lastChecked)
                print("⏰ Time since last check: \(Int(timeSinceLastCheck)) seconds")
                
                if timeSinceLastCheck > 3600 {
                    print("🔄 Data is stale, marking for auto-refresh")
                    pendingAutoRefresh = true
                } else {
                    print("✅ Cached data is fresh")
                }
            } else {
                print("❌ No cached data found, marking for auto-refresh")
                pendingAutoRefresh = true
            }
        } else {
            print("❌ No saved registration found")
        }
    }
    
    private func checkForAutoRefresh() {
        print("🔍 Checking for auto-refresh - pending: \(pendingAutoRefresh), registration: '\(carRegistration)'")
        if pendingAutoRefresh && !carRegistration.isEmpty {
            print("🚀 Triggering auto-refresh")
            performAutoRefresh()
        } else {
            print("⏸️ Auto-refresh not triggered - pending: \(pendingAutoRefresh), hasRegistration: \(!carRegistration.isEmpty)")
        }
    }
    
    private func performAutoRefresh() {
        guard !carRegistration.isEmpty,
              networkMonitor.isReliablyConnected,
              !isLoading,
              hasInitialized,
              pendingAutoRefresh else {
            return
        }
        
        pendingAutoRefresh = false
        
        // Perform a silent refresh (don't show loading state for auto-refresh)
        let currentErrorMessage = errorMessage
        errorMessage = nil
        
        print("🔄 Performing auto-refresh for \(carRegistration)")
        
        enquiryService.checkVehicleStatus(registration: carRegistration)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        print("✅ Auto-refresh completed successfully")
                        break
                    case .failure(let error):
                        print("❌ Auto-refresh failed: \(error)")
                        // For auto-refresh, only show error if it's critical
                        if case .invalidRegistration = error {
                            self?.errorMessage = error.localizedDescription
                        } else {
                            // Keep existing cached data and restore previous error state
                            self?.errorMessage = currentErrorMessage
                        }
                    }
                },
                receiveValue: { [weak self] status in
                    print("📊 Auto-refresh received data: Tax=\(status.taxInfo.status), MOT=\(status.motInfo.status)")
                    self?.vehicleStatus = status
                    self?.lastChecked = status.lastChecked
                    self?.repository.saveVehicleStatus(status)
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func checkVehicleStatus() {
        guard !carRegistration.isEmpty else {
            errorMessage = "Please enter a vehicle registration"
            return
        }
        
        // Use more lenient network checking - only block if we're sure there's no connection
        guard networkMonitor.isConnectedOrUnknown else {
            errorMessage = "No internet connection"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        enquiryService.checkVehicleStatus(registration: carRegistration)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    switch completion {
                    case .finished:
                        self?.errorMessage = nil
                    case .failure(let error):
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] status in
                    self?.vehicleStatus = status
                    self?.lastChecked = status.lastChecked
                    self?.repository.saveVehicleStatus(status)
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func saveRegistration() {
        repository.saveRegistration(carRegistration)
    }
    
    func cancelFetch() {
        enquiryService.cancelCurrentRequest()
        isLoading = false
    }
    
    func clearData() {
        repository.clearData()
        vehicleStatus = nil
        carRegistration = ""
        lastChecked = nil
        errorMessage = nil
    }
    
    private func handleError(_ error: VehicleEnquiryError) {
        errorMessage = error.localizedDescription
        
        // For certain errors, provide additional context
        switch error {
        case .networkError(let message):
            // If it's a network error but we think we have connection, it might be a false negative
            if networkMonitor.isConnected && message.contains("not connected") {
                errorMessage = "Connection issue detected. Tap 'Check Status' to retry."
            }
        case .websiteStructureChanged:
            errorMessage = "\(error.localizedDescription)\n\(error.recoverySuggestion ?? "")"
        case .rateLimited:
            // Auto-retry after a delay for rate limiting
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.isLoading == false {
                    self?.checkVehicleStatus()
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Computed Properties
    
    var taxStatusIcon: String {
        guard let status = vehicleStatus else {
            return isLoading ? "exclamationmark.triangle.fill" : "car.circle.fill"
        }
        return status.taxInfo.isValid ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    var taxStatusColor: Color {
        guard let status = vehicleStatus else {
            return isLoading ? .orange : .secondary
        }
        return status.taxInfo.isValid ? .green : .red
    }
    
    var motStatusIcon: String {
        guard let status = vehicleStatus else {
            return isLoading ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
        }
        return status.motInfo.isValid ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    var motStatusColor: Color {
        guard let status = vehicleStatus else {
            return isLoading ? .orange : .secondary
        }
        return status.motInfo.isValid ? .green : .red
    }
    
    var taxStatusText: String {
        guard let status = vehicleStatus else {
            return "Loading Tax status"
        }
        return status.taxInfo.status
            .replacingOccurrences(of: "✓", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    var motStatusText: String {
        guard let status = vehicleStatus else {
            return "Loading MOT status"
        }
        return status.motInfo.status
            .replacingOccurrences(of: "✓|✗", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var taxDueText: String? {
        guard let taxDue = vehicleStatus?.taxInfo.dueDate,
              !taxDue.isEmpty else { return nil }
        return "Due: \(taxDue.replacingOccurrences(of: "Tax due:", with: "").trimmingCharacters(in: .whitespacesAndNewlines))"
    }
    
    var motExpiryText: String? {
        guard let motExpiry = vehicleStatus?.motInfo.expiryDate,
              !motExpiry.isEmpty else { return nil }
        return motExpiry.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
