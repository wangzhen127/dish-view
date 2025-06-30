// MenuParsingTests.swift
// MenuVisualizerTests
//
// Created by Jules on $(date +%F).
//

import XCTest
@testable import MenuVisualizer // Ensure your main app target is importable

class MenuParsingTests: XCTestCase {

    var mainView: MainView!
    var mockImageSearchService: MockImageSearchServiceForParsing!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockImageSearchService = MockImageSearchServiceForParsing()
        // Inject the mock service into MainView
        mainView = MainView(imageSearchService: mockImageSearchService)
    }

    override func tearDownWithError() throws {
        mainView = nil
        mockImageSearchService = nil
        try super.tearDownWithError()
    }

    func testParseMenuText_WithSimpleText_ShouldCreateMenuItems() {
        let menuText = "Dish 1\nDish 2\nAnother Dish"

        // We need to simulate the part of detectAndParseMenu that calls parseMenuText
        // and handles the async nature of image fetching.
        // For this unit test, we'll focus solely on the text splitting aspect of parseMenuText.
        // The image fetching part is harder to unit test without significant mocking.

        // Create an expectation for the asynchronous operation
        let expectation = self.expectation(description: "Parsing menu text and attempting to fetch images")

        // Modify parseMenuText in MainView or create a testable version if necessary.
        // For now, let's assume parseMenuText updates menuItems property.
        // We will directly call parseMenuText and then check the menuItems count.
        // This requires making menuItems accessible for testing or having a completion handler.

        // To test this properly, parseMenuText would ideally have a completion handler
        // or the menuItems property should be @Published and observed.
        // Given the current structure, we will make a simplified assertion.

        mainViewViewModel.parseMenuText(menuText) // This is async due to image search

        // We need to wait for the image search simulation to complete.
        // A better way would be to inject a mock ImageSearchService.
        // For simplicity here, we'll add a short delay, but this is not robust.
        // The mock service will call completion immediately.
        mainView.parseMenuText(menuText)

        // Wait for the expectation
        waitForExpectations(timeout: 1, handler: nil)

        // Assertions after expectation is fulfilled
        XCTAssertEqual(self.mainView.menuItems.count, 3, "Should parse 3 menu items from the text.")
        XCTAssertTrue(self.mockImageSearchService.searchImageCallCount == 3, "Search image should be called for each dish.")
        XCTAssertEqual(self.mainView.menuItems.first?.name, "Dish 1", "First dish name should be 'Dish 1'.")
        XCTAssertEqual(self.mainView.menuItems[1].name, "Dish 2", "Second dish name should be 'Dish 2'.")
        XCTAssertEqual(self.mainView.menuItems.last?.name, "Another Dish", "Last dish name should be 'Another Dish'.")
    }

    func testParseMenuText_WithEmptyText_ShouldResultInZeroMenuItems() {
        let menuText = ""
        let expectation = self.expectation(description: "Parsing empty menu text")
        mockImageSearchService.completionExpectation = expectation // Mock will fulfill this

        mainView.parseMenuText(menuText)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(self.mainView.menuItems.count, 0, "Should parse 0 menu items from empty text.")
        XCTAssertTrue(self.mockImageSearchService.searchImageCallCount == 0, "Search image should not be called for empty text.")
    }
}


// Mock ImageSearchService specifically for MenuParsingTests to control image fetching behavior during parsing
class MockImageSearchServiceForParsing: ImageSearchServiceProtocol {
    var searchImageCallCount = 0
    var completionExpectation: XCTestExpectation?

    func searchImage(for dishName: String, completion: @escaping (UIImage?) -> Void) {
        searchImageCallCount += 1
        // Simulate async behavior by calling completion on the next run loop cycle
        DispatchQueue.main.async {
            completion(nil) // Return nil image for simplicity in parsing tests
            // If this is the last expected call, fulfill the expectation
            // This logic might need adjustment based on how many items are parsed
            // For simplicity, we'll rely on the DispatchGroup in MainView's parseMenuText
            // and fulfill expectation after parseMenuText completes.
        }
    }

    // Helper to fulfill expectation after all searchImage calls are expected to be done.
    // This is tricky because parseMenuText has its own DispatchGroup.
    // The expectation in the test should be fulfilled by the group.notify in parseMenuText.
}
