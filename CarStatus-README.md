# CarStatus

A macOS application for checking UK vehicle tax and MOT status.

## Development Setup

This project uses Xcode for development and can be built as a macOS app.

### Quick Start

```bash
# Set up the development environment
./scripts/setup.sh

# Build and install the app
./scripts/build-local-app.sh
```

### Project Structure

```
CarStatus/
├── car-status.xcodeproj            # Xcode project
├── car-status/                     # App source code
│   ├── Models/                     # Data models
│   ├── Services/                   # Business services  
│   ├── ViewModels/                 # View models
│   ├── ContentView.swift           # Main UI
│   └── Assets.xcassets/            # App icons and assets
└── scripts/                       # Build scripts
```

### Building the App

```bash
# Build and install to Applications folder
./scripts/build-local-app.sh

# The app will be available from:
# - Spotlight search
# - Applications folder
# - Menu bar (car icon)
```

### Development Workflow

```bash
# 1. Open project in Xcode
open car-status.xcodeproj

# 2. Make changes and test
# Product → Build (Cmd+B)
# Product → Run (Cmd+R)

# 3. Build final app when ready
./scripts/build-local-app.sh
```

# Run tests
./scripts/dev.sh test

# Clean build artifacts
./scripts/dev.sh clean

# Resolve dependencies
./scripts/dev.sh resolve
```

### Architecture

- **CarStatusCore**: Shared business logic library
  - Models: `VehicleStatus`, `TaxInfo`, `MOTInfo`
  - Services: `VehicleService`, `NetworkMonitor`, `VehicleRepository`
  - Protocols: Clean interfaces for testability

- **CarStatusCLI**: Command line interface for development and testing

### Next Steps

1. **Enhanced Scraping**: Replace mock data with real WebKit scraping
2. **macOS App**: Create Xcode project that uses CarStatusCore
3. **Caching**: Improve local data storage and cache management
4. **Testing**: Add more comprehensive test coverage

### Requirements

- macOS 12.0+
- Swift 5.8+
- Xcode Command Line Tools
