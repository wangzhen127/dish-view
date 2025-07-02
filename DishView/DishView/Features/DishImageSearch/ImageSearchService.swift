import Foundation
import UIKit

class ImageSearchService: ObservableObject {
    static let shared = ImageSearchService()
    
    // MARK: - Configuration
    private let apiKey: String
    private let searchEngineId: String
    private let baseURL = "https://www.googleapis.com/customsearch/v1"
    
    private init() {
        // Load API credentials from secure storage or environment
        self.apiKey = Self.loadAPIKey()
        self.searchEngineId = Self.loadSearchEngineId()
    }
    
    func searchDishImage(dishName: String, restaurantName: String? = nil) async throws -> UIImage? {
        // Construct search query
        let query = buildSearchQuery(dishName: dishName, restaurantName: restaurantName)
        
        // Search for image URLs
        let imageURLs = try await searchWithGoogleAPI(query: query)
        
        // Download the first available image
        for urlString in imageURLs {
            do {
                let image = try await downloadImage(from: urlString)
                return image
            } catch {
                // Continue to next URL if this one fails
                continue
            }
        }
        
        // Return nil if no images could be downloaded
        return nil
    }
    
    func searchDishImages(for dishes: [Dish], restaurantName: String? = nil) async -> [Dish] {
        var updatedDishes = dishes
        
        for (index, dish) in dishes.enumerated() {
            updatedDishes[index].isImageLoading = true
            
            do {
                if let image = try await searchDishImage(dishName: dish.name, restaurantName: restaurantName) {
                    updatedDishes[index].image = image
                    updatedDishes[index].imageLoadError = false
                } else {
                    updatedDishes[index].imageLoadError = true
                }
            } catch {
                updatedDishes[index].imageLoadError = true
            }
            
            updatedDishes[index].isImageLoading = false
        }
        
        return updatedDishes
    }
    
    // MARK: - Private Methods
    
    private func buildSearchQuery(dishName: String, restaurantName: String?) -> String {
        var query = dishName
        
        // Add restaurant name if available to improve search accuracy
        if let restaurantName = restaurantName, !restaurantName.isEmpty {
            query += " \(restaurantName)"
        }
        
        // Add food-related keywords to improve image search results
        query += " food dish meal"
        
        return query
    }
    
    private func searchWithGoogleAPI(query: String) async throws -> [String] {
        // Validate API credentials
        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY" else {
            throw ImageSearchError.apiError("Google Custom Search API key not configured")
        }
        
        guard !searchEngineId.isEmpty, searchEngineId != "YOUR_SEARCH_ENGINE_ID" else {
            throw ImageSearchError.apiError("Google Custom Search Engine ID not configured")
        }
        
        // Construct URL with query parameters
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: searchEngineId),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "searchType", value: "image"),
            URLQueryItem(name: "num", value: "3"), // Get 3 results for better chances
            URLQueryItem(name: "imgSize", value: "medium"), // Prefer medium-sized images
            URLQueryItem(name: "imgType", value: "photo"), // Prefer photos over drawings
            URLQueryItem(name: "safe", value: "active") // Safe search
        ]
        
        guard let url = components?.url else {
            throw ImageSearchError.invalidURL
        }
        
        // Create URL request with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        
        // Perform the search request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageSearchError.apiError("Invalid HTTP response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ImageSearchError.apiError("API request failed with status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Parse the response
        do {
            let searchResponse = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
            
            // Extract image URLs from the response
            let imageURLs = searchResponse.items?.compactMap { item in
                item.link
            } ?? []
            
            return imageURLs
        } catch {
            throw ImageSearchError.apiError("Failed to parse API response: \(error.localizedDescription)")
        }
    }
    
    private func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw ImageSearchError.invalidURL
        }
        
        // Create URL request with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        
        // Download image data
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageSearchError.invalidImageData
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ImageSearchError.apiError("Image download failed with status \(httpResponse.statusCode)")
        }
        
        // Validate content type
        guard let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
              contentType.hasPrefix("image/") else {
            throw ImageSearchError.invalidImageData
        }
        
        // Create UIImage from data
        guard let image = UIImage(data: data) else {
            throw ImageSearchError.invalidImageData
        }
        
        return image
    }
}

// MARK: - Secure Credential Management
extension ImageSearchService {
    private static func loadAPIKey() -> String {
        // Priority order for loading API key:
        // 1. Environment variable (for production)
        // 2. Configuration file (for development)
        // 3. Default placeholder
        
        // Check environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_CUSTOM_SEARCH_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }
        
        // Check configuration file
        if let configKey = loadFromConfigFile(key: "GOOGLE_CUSTOM_SEARCH_API_KEY") {
            return configKey
        }
        
        // Return placeholder for development
        return "YOUR_API_KEY"
    }
    
    private static func loadSearchEngineId() -> String {
        // Priority order for loading Search Engine ID:
        // 1. Environment variable (for production)
        // 2. Configuration file (for development)
        // 3. Default placeholder
        
        // Check environment variable first
        if let envId = ProcessInfo.processInfo.environment["GOOGLE_CUSTOM_SEARCH_ENGINE_ID"],
           !envId.isEmpty {
            return envId
        }
        
        // Check configuration file
        if let configId = loadFromConfigFile(key: "GOOGLE_CUSTOM_SEARCH_ENGINE_ID") {
            return configId
        }
        
        // Return placeholder for development
        return "YOUR_SEARCH_ENGINE_ID"
    }
    
    private static func loadFromConfigFile(key: String) -> String? {
        // Load from a configuration file (e.g., Config.plist)
        // This is for development purposes only
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let value = config[key] as? String,
              !value.isEmpty else {
            return nil
        }
        
        return value
    }
}

// MARK: - Error Types
enum ImageSearchError: Error, LocalizedError {
    case invalidURL
    case invalidImageData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidImageData:
            return "Invalid image data received"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

// MARK: - Response Models
struct GoogleSearchResponse: Codable {
    let items: [GoogleSearchItem]?
    let searchInformation: SearchInformation?
    
    enum CodingKeys: String, CodingKey {
        case items
        case searchInformation = "searchInformation"
    }
}

struct GoogleSearchItem: Codable {
    let link: String?
    let title: String?
    let snippet: String?
    let image: ImageInfo?
    
    enum CodingKeys: String, CodingKey {
        case link
        case title
        case snippet
        case image
    }
}

struct ImageInfo: Codable {
    let contextLink: String?
    let thumbnailLink: String?
    let thumbnailHeight: String?
    let thumbnailWidth: String?
}

struct SearchInformation: Codable {
    let searchTime: Double?
    let formattedSearchTime: String?
    let totalResults: String?
    let formattedTotalResults: String?
} 