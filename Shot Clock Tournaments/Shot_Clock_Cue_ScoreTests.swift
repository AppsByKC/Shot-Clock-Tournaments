import XCTest
import SwiftUI
@testable import Shot_Clock_Tournaments // Replace with your module name

final class TextFieldURLTests: XCTestCase {
    func testValidURLInput() {
        // Simulate a valid URL input
        let validURL = "https://www.cuescore.com"
        var cuescoreLink = ""
        
        // Bind the TextField to the variable
        let binding = Binding<String>(
            get: { cuescoreLink },
            set: { cuescoreLink = $0 }
        )
        
        // Simulate user input
        binding.wrappedValue = validURL
        
        // Assert that the input matches the expected valid URL
        XCTAssertEqual(cuescoreLink, validURL, "The TextField should accept valid URLs.")
    }
    
    func testInvalidURLInput() {
        // Simulate an invalid URL input
        let invalidURL = "invalid_url"
        var cuescoreLink = ""
        
        // Bind the TextField to the variable
        let binding = Binding<String>(
            get: { cuescoreLink },
            set: { cuescoreLink = $0 }
        )
        
        // Simulate user input
        binding.wrappedValue = invalidURL
        
        // Assert that the input does not match a valid URL format
        XCTAssertFalse(isValidURL(cuescoreLink), "The TextField should reject invalid URLs.")
    }
    
    func testEmptyInput() {
        // Simulate an empty input
        var cuescoreLink = ""
        
        // Bind the TextField to the variable
        let binding = Binding<String>(
            get: { cuescoreLink },
            set: { cuescoreLink = $0 }
        )
        
        // Simulate user input
        binding.wrappedValue = ""
        
        // Assert that the input is empty
        XCTAssertEqual(cuescoreLink, "", "The TextField should handle empty inputs gracefully.")
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
