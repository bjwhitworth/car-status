# CarStatus

A macOS menu bar application for checking UK vehicle tax and MOT status in real-time.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.8+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

✅ **Real-time Status Checks** - Fetches current tax and MOT information from the UK government service  
✅ **Menu Bar Integration** - Quick access from your macOS menu bar  
✅ **Auto-refresh** - Automatically checks status every hour  
✅ **Offline Support** - Caches data and works without internet  
✅ **Network Monitoring** - Smart handling of connectivity issues  
✅ **Data Persistence** - Remembers your vehicle registration  
✅ **Clean SwiftUI Interface** - Native macOS design  

## Screenshots

The app runs as a menu bar utility showing your vehicle's current status at a glance.

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later (for building from source)
- Active internet connection for status checks

## Installation

### Option 1: Build from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/car-status.git
cd car-status

# Set up the development environment
./scripts/setup.sh

# Build and install the app
./scripts/build-local-app.sh
```

The app will be installed to `/Applications/car-status.app`

### Option 2: Manual Build in Xcode

1. Open `car-status.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (⌘R)

## Usage

1. **Launch the app** - Find it in Applications or via Spotlight (⌘Space)
2. **Enter your registration** - Type your UK vehicle registration number
3. **View status** - Tax and MOT status appear automatically
4. **Auto-updates** - The app checks for updates every hour

### Menu Bar Icon

Click the car icon in your menu bar to:
- View current tax and MOT status
- Check last update time
- Manually refresh status
- Enter a different vehicle registration

## Architecture

### Clean Architecture with MVVM

```
car-status/
├── Models/
│   ├── VehicleStatus.swift          # Core data model
│   └── VehicleEnquiryError.swift    # Error handling
├── Services/
│   ├── VehicleEnquiryService.swift  # WebKit-based scraping
│   ├── VehicleRepository.swift      # Data persistence
│   └── NetworkMonitor.swift         # Connectivity monitoring
├── ViewModels/
│   └── VehicleStatusViewModel.swift # Business logic
└── ContentView.swift                # SwiftUI interface
```

### Key Components

- **VehicleEnquiryService**: Scrapes the gov.uk vehicle enquiry service using WebKit
- **VehicleRepository**: Handles data persistence using UserDefaults
- **NetworkMonitor**: Monitors network connectivity for reliable operation
- **VehicleStatusViewModel**: Manages state and coordinates between services and UI

## Development

### Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install
```

### Building

```bash
# Clean build
./scripts/setup.sh

# Build and install
./scripts/build-local-app.sh
```

### Project Structure

```
CarStatus/
├── car-status.xcodeproj/       # Xcode project
├── car-status/                 # Source code
│   ├── Models/                 # Data models
│   ├── Services/               # Business logic
│   ├── ViewModels/             # View models
│   ├── ContentView.swift       # Main UI
│   ├── Assets.xcassets/        # App icons & resources
│   ├── Info.plist              # App configuration
│   └── car_status.entitlements # Security permissions
├── scripts/
│   ├── setup.sh                # Development setup
│   └── build-local-app.sh      # Build script
└── README.md                   # This file
```

## Technical Details

### WebKit Integration

The app uses WebKit to interact with the official UK government vehicle enquiry service:
- Automated form submission
- JavaScript-based page interaction
- Response parsing and data extraction
- Retry logic and timeout handling

### Data Persistence

- Registration number stored in UserDefaults
- Status cached for offline access
- Last check timestamp tracking

### Network Handling

- Automatic retry on network failures
- Rate limiting (2-second minimum between requests)
- Graceful degradation when offline
- Network connectivity monitoring

### Security & Privacy

- **No data collection** - All data stays on your device
- **Direct government access** - No third-party services
- **Hardened Runtime** enabled for security
- **Sandboxed** with minimal permissions

## Permissions Required

The app requires these macOS permissions:
- **Network Access** - To check vehicle status on gov.uk
- **Hardened Runtime** - For security compliance

No personal data is collected or transmitted beyond what's necessary to query the government service.

## Troubleshooting

### App won't launch
```bash
# Check if the app is properly signed
codesign -vvv /Applications/car-status.app

# Rebuild and reinstall
./scripts/build-local-app.sh
```

### Network errors
- Check your internet connection
- Verify the gov.uk service is accessible
- The app caches data for offline viewing

### "Invalid Registration" error
- Use format: `AB12 CDE` (spaces optional)
- Supported formats: Current (AB12 CDE), Prefix (A123 BCD), Suffix (ABC 123D)

## Limitations

- **UK vehicles only** - Only works with UK vehicle registrations
- **Government service dependency** - Relies on gov.uk availability
- **macOS only** - Not available for iOS, Windows, or Linux

## Future Enhancements

- [ ] Multiple vehicle support
- [ ] Notification reminders before tax/MOT expiry
- [ ] Export status history
- [ ] iCloud sync across devices
- [ ] iOS companion app

## Contributing

This is a personal project, but suggestions and improvements are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- UK Government Vehicle Enquiry Service for providing the data
- Built with Swift and SwiftUI
- Uses WebKit for web scraping

## Support

For issues or questions:
- Open an issue on GitHub
- Check the [Troubleshooting](#troubleshooting) section

## Disclaimer

This application is not affiliated with, endorsed by, or connected to the UK Government or DVLA. It simply provides a convenient interface to publicly available vehicle information.

---

**Note**: This app scrapes the government website and may break if the website structure changes. Updates may be required to maintain functionality.
