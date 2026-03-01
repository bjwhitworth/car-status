import XCTest
@testable import car_status

final class car_statusTests: XCTestCase {

    func testValidUKRegistrations() {
        let service = VehicleEnquiryService()
        
        // These should be valid
        XCTAssertTrue(service.isValidUKRegistration("AB12 CDE"))
        XCTAssertTrue(service.isValidUKRegistration("A123 BCD"))
        XCTAssertTrue(service.isValidUKRegistration("ABC 123D"))
        XCTAssertTrue(service.isValidUKRegistration("1234 AB"))
        XCTAssertTrue(service.isValidUKRegistration("AB12CDE")) // Without spaces
        
        // These should be invalid
        XCTAssertFalse(service.isValidUKRegistration("123456"))
        XCTAssertFalse(service.isValidUKRegistration("INVALID"))
        XCTAssertFalse(service.isValidUKRegistration("A1 B2 C3"))
    }
    
    func testViewModelStatusTextParsing() {
        let viewModel = VehicleStatusViewModel()
        
        // Test with real scraped formatting
        let mockTaxInfo = TaxInfo(status: " ✓ Taxed ", dueDate: "Tax due:\n 01 January 2025 ")
        let mockMotInfo = MOTInfo(status: " ✗ Expired ", expiryDate: "\n01 February 2025\n")
        
        let mockStatus = VehicleStatus(
            registration: "AB12 CDE",
            taxInfo: mockTaxInfo,
            motInfo: mockMotInfo,
            lastChecked: Date()
        )
        
        viewModel.vehicleStatus = mockStatus
        
        // Tax text should strip the tick and whitespace
        XCTAssertEqual(viewModel.taxStatusText, "Taxed")
        XCTAssertEqual(viewModel.taxDueText, "Due: 01 January 2025")
        
        // MOT text should strip regex and newlines
        XCTAssertEqual(viewModel.motStatusText, "Expired")
        XCTAssertEqual(viewModel.motExpiryText, "01 February 2025")
    }
}
