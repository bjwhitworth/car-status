# Car Status App - Architecture Improvements

## Overview
This macOS menubar application has been refactored to implement better architecture and reliability patterns.

## New Architecture

### Models
- **VehicleStatus.swift**: Core data model representing a vehicle's tax and MOT status
- **VehicleEnquiryError.swift**: Comprehensive error handling with user-friendly messages

### Services
- **VehicleEnquiryService.swift**: Handles web scraping with retry logic, timeout handling, and rate limiting
- **VehicleRepository.swift**: Abstracts data persistence with protocol-based design
- **NetworkMonitor.swift**: Monitors network connectivity for better error handling

### ViewModels
- **VehicleStatusViewModel.swift**: MVVM pattern with reactive data binding and computed properties

## Key Improvements Implemented

### Set 1: Architecture & Code Organization ✅
- ✅ Separated concerns into dedicated service classes
- ✅ Created proper Swift data models (VehicleStatus, TaxInfo, MOTInfo)
- ✅ Implemented repository pattern for data persistence
- ✅ Comprehensive error handling with custom error types
- ✅ MVVM architecture with reactive data binding

### Set 2: Reliability & Robustness ✅
- ✅ Retry logic with exponential backoff (max 3 retries)
- ✅ Timeout handling (30 second timeout)
- ✅ Network connectivity monitoring
- ✅ Rate limiting (2 second intervals between requests)
- ✅ Proper error recovery strategies
- ✅ Input validation for UK registration numbers
- ✅ Auto-refresh for stale data (1 hour threshold)

## Usage

The app maintains the same user interface but now uses a more robust backend:

1. **Data Caching**: Vehicle status is cached locally and auto-refreshes when stale
2. **Network Awareness**: Shows appropriate errors when offline
3. **Better Error Messages**: User-friendly error messages with recovery suggestions
4. **Retry Logic**: Automatically retries failed requests with backoff
5. **Input Validation**: Validates UK registration format before making requests

## Technical Details

### Error Handling
The app now handles various error scenarios:
- Invalid registration format
- Network connectivity issues
- Government website unavailability
- Rate limiting
- Request timeouts
- Website structure changes

### Data Flow
1. User enters registration → ViewModel validates input
2. ViewModel checks network connectivity
3. Service makes request with retry logic
4. Data is parsed and cached locally
5. UI updates reactively through Combine publishers

### Performance
- Non-blocking UI operations
- Background processing
- Efficient memory management
- Proper cleanup of resources

## Future Enhancements
Ready for implementing sets 3-11 from the improvement roadmap:
- Multiple vehicle support
- Notification system
- Advanced UI features
- Testing framework
- Distribution improvements
