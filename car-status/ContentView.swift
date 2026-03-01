import SwiftUI
import WebKit

@main
struct MyApp: App {
    @StateObject private var vehicleStatusViewModel = VehicleStatusViewModel()

    init() {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }
    
    var body: some Scene {
        MenuBarExtra(content: {
            VStack(spacing: 8) {
                // Status Section
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 2) {
                                    Text(vehicleStatusViewModel.taxStatusText)
                                }
                                if let taxDue = vehicleStatusViewModel.taxDueText {
                                    Text(taxDue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.subheadline)
                        } icon: {
                            Image(systemName: vehicleStatusViewModel.taxStatusIcon)
                                .foregroundStyle(vehicleStatusViewModel.taxStatusColor)
                        }
                        
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 2) {
                                    Text(vehicleStatusViewModel.motStatusText)
                                }
                                if let motExpiry = vehicleStatusViewModel.motExpiryText {
                                    Text(motExpiry)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.subheadline)
                        } icon: {
                            Image(systemName: vehicleStatusViewModel.motStatusIcon)
                                .foregroundStyle(vehicleStatusViewModel.motStatusColor)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal, 8)
                
                // Input Section
                VStack(spacing: 6) {
                    HStack {
                        TextField("Enter Car Registration", text: $vehicleStatusViewModel.carRegistration)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                            .padding(8)
                            .background(Color(.windowBackgroundColor).opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                            .onHover { _ in }
                        
                        if !vehicleStatusViewModel.carRegistration.isEmpty {
                            Button(action: { vehicleStatusViewModel.carRegistration = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .imageScale(.small)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Button(action: {
                        if vehicleStatusViewModel.isLoading {
                            vehicleStatusViewModel.cancelFetch()
                        } else {
                            vehicleStatusViewModel.checkVehicleStatus()
                            vehicleStatusViewModel.saveRegistration()
                        }
                    }) {
                        HStack {
                            if vehicleStatusViewModel.isLoading {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Cancel")
                                    .font(.subheadline)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Check Status")
                                    .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vehicleStatusViewModel.carRegistration.isEmpty && !vehicleStatusViewModel.isLoading)
                    .keyboardShortcut(.return, modifiers: [])
                    .help("Check vehicle tax and MOT status")
                }
                .padding(.horizontal, 12)
                
                if let error = vehicleStatusViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                if let lastChecked = vehicleStatusViewModel.lastChecked {
                    Text("Last checked: \(lastChecked, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 12)
            .frame(width: 240)
        }, label: {
            Image(systemName: "car.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .opacity(vehicleStatusViewModel.isLoading ? 0.5 : 1.0)
                .animation(.easeInOut, value: vehicleStatusViewModel.isLoading)
        })
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Car Status") {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
            CommandGroup(replacing: .newItem) { }
        }
    }
}
