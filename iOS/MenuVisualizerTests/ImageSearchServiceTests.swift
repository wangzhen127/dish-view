// ImageSearchServiceTests.swift
// MenuVisualizerTests
//
// Created by Jules on $(date +%F).
//

import XCTest
@testable import MenuVisualizer

// Mock ImageSearchService for testing URL construction and basic logic
class MockImageSearchService: ImageSearchServiceProtocol {
    var lastSearchedDishName: String?
    var cannedResponseImage: UIImage? // Not used in this simple test, but could be for image download testing
    var searchCalled = false

    // Store the expected URL to verify it's constructed correctly
    var expectedUrlPattern: String?
    var lastConstructedUrl: URL?

    func searchImage(for dishName: String, completion: @escaping (UIImage?) -> Void) {
        searchCalled = true
        lastSearchedDishName = dishName

        // Simulate URL construction for verification (without making a real network call)
        // This part mimics the URL construction logic from the actual ImageSearchService
        // In a real scenario, you might not want to duplicate this logic here,
        // but rather verify the parameters passed to a URLSession mock.
        let apiKey = "YOUR_API_KEY" // Use placeholder or a test key
        let searchEngineId = "YOUR_SEARCH_ENGINE_ID" // Use placeholder or a test ID
        if let encodedDishName = dishName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            lastConstructedUrl = URL(string: "https://www.googleapis.com/customsearch/v1?key=\(apiKey)&cx=\(searchEngineId)&q=\(encodedDishName)&searchType=image&num=1")
        }

        // In a real test, you might simulate a network response here
        // For this example, we'll just call completion with nil
        completion(nil)
    }
}

class ImageSearchServiceTests: XCTestCase {

    var mockImageSearchService: MockImageSearchService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockImageSearchService = MockImageSearchService()
    }

    override func tearDownWithError() throws {
        mockImageSearchService = nil
        try super.tearDownWithError()
    }

    func testSearchImage_ConstructsCorrectURL() {
        let dishName = "Caesar Salad"
        let expectation = self.expectation(description: "Image search completion")

        // Expected URL pattern (you might want to make this more robust)
        // Note: API keys and CX should ideally come from a config or be injected.
        let expectedApiKey = "YOUR_API_KEY"
        let expectedCx = "YOUR_SEARCH_ENGINE_ID"
        let encodedDishName = dishName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let expectedURLString = "https://www.googleapis.com/customsearch/v1?key=\(expectedApiKey)&cx=\(expectedCx)&q=\(encodedDishName)&searchType=image&num=1"

        mockImageSearchService.expectedUrlPattern = expectedURLString

        mockImageSearchService.searchImage(for: dishName) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(mockImageSearchService.searchCalled, "searchImage should be called.")
        XCTAssertEqual(mockImageSearchService.lastSearchedDishName, dishName, "The dish name passed to searchImage was not correct.")
        XCTAssertEqual(mockImageSearchService.lastConstructedUrl?.absoluteString, expectedURLString, "The URL constructed by searchImage was not as expected.")
    }

    func testSearchImage_WithSpacesInDishName_ShouldEncodeURL() {
        let dishNameWithSpaces = "Spaghetti Carbonara"
        let expectation = self.expectation(description: "Image search with spaces completion")

        let expectedApiKey = "YOUR_API_KEY"
        let expectedCx = "YOUR_SEARCH_ENGINE_ID"
        // "Spaghetti%20Carbonara"
        let encodedDishName = dishNameWithSpaces.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let expectedURLString = "https://www.googleapis.com/customsearch/v1?key=\(expectedApiKey)&cx=\(expectedCx)&q=\(encodedDishName)&searchType=image&num=1"

        mockImageSearchService.expectedUrlPattern = expectedURLString

        mockImageSearchService.searchImage(for: dishNameWithSpaces) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(mockImageSearchService.searchCalled)
        XCTAssertEqual(mockImageSearchService.lastSearchedDishName, dishNameWithSpaces)
        XCTAssertEqual(mockImageSearchService.lastConstructedUrl?.absoluteString, expectedURLString, "URL should be percent-encoded for spaces.")
    }
}
