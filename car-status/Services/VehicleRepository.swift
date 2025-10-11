//
//  VehicleRepository.swift
//  car-status
//
//  Created by GitHub Copilot on 13/07/2025.
//

import Foundation

protocol VehicleRepositoryProtocol {
    func saveVehicleStatus(_ status: VehicleStatus)
    func loadVehicleStatus(for registration: String) -> VehicleStatus?
    func getSavedRegistration() -> String?
    func saveRegistration(_ registration: String)
    func clearData()
}

final class VehicleRepository: VehicleRepositoryProtocol {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private enum Keys {
        static let savedRegistration = "savedRegistration"
        static let vehicleStatusPrefix = "vehicleStatus_"
    }
    
    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func saveVehicleStatus(_ status: VehicleStatus) {
        let key = Keys.vehicleStatusPrefix + status.registration.uppercased()
        if let data = try? encoder.encode(status) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func loadVehicleStatus(for registration: String) -> VehicleStatus? {
        let key = Keys.vehicleStatusPrefix + registration.uppercased()
        guard let data = userDefaults.data(forKey: key),
              let status = try? decoder.decode(VehicleStatus.self, from: data) else {
            return nil
        }
        return status
    }
    
    func getSavedRegistration() -> String? {
        return userDefaults.string(forKey: Keys.savedRegistration)
    }
    
    func saveRegistration(_ registration: String) {
        userDefaults.set(registration, forKey: Keys.savedRegistration)
    }
    
    func clearData() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.vehicleStatusPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.removeObject(forKey: Keys.savedRegistration)
    }
}
