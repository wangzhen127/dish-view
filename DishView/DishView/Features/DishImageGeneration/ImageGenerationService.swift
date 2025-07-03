import Foundation
import UIKit

class ImageGenerationService: ObservableObject {
    static let shared = ImageGenerationService()
    
    // MARK: - Configuration
    private let geminiApiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent"
    
    private init() {
        self.geminiApiKey = Self.loadGeminiAPIKey()
    }
    
    func generateDishImage(dishName: String, restaurantName: String? = nil) async throws -> UIImage? {
        print("🎨 Generating image for dish: '\(dishName)'")
        if let restaurantName = restaurantName {
            print("🏪 Restaurant: '\(restaurantName)'")
        }
        
        do {
                    // Single API call to generate image
        let imageData = try await generateImage(dishName: dishName, restaurantName: restaurantName)
            
            // Convert the image data to UIImage
            guard let image = UIImage(data: imageData) else {
                throw ImageGenerationError.invalidImageData
            }
            
            print("✅ Generated realistic image for '\(dishName)'")
            return image
            
        } catch {
            print("❌ Image generation failed: \(error)")
            throw error
        }
    }
    
    func generateDishImagesProgressive(
        for dishes: [Dish], 
        restaurantName: String? = nil,
        onDishUpdated: @escaping (Dish) -> Void,
        onComplete: @escaping () -> Void
    ) async {
        print("🍽️ Starting parallel image generation for \(dishes.count) dishes with concurrency of 3")
        if let restaurantName = restaurantName {
            print("🏪 Restaurant: \(restaurantName)")
        }
        
        // Create a task group for parallel processing with concurrency limit of 3
        await withThrowingTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            var completedTasks = 0
            let totalTasks = dishes.count
            
            // Process dishes with concurrency limit
            for dish in dishes {
                // Wait if we've reached the concurrency limit
                while activeTasks >= 3 {
                    if let _ = try? await group.next() {
                        activeTasks -= 1
                        completedTasks += 1
                    }
                }
                
                // Create a local copy of the dish to avoid captured variable warning
                let dishCopy = dish
                group.addTask {
                    do {
                        let imageData = try await self.generateImage(dishName: dishCopy.name, restaurantName: restaurantName)
                        if let image = UIImage(data: imageData) {
                            var updatedDish = dishCopy
                            updatedDish.image = image
                            await MainActor.run {
                                onDishUpdated(updatedDish)
                            }
                            print("✅ Generated image for '\(dishCopy.name)' (ID: \(dishCopy.id))")
                        }
                    } catch {
                        print("💥 Error generating image for '\(dishCopy.name)' (ID: \(dishCopy.id)): \(error)")
                    }
                }
                activeTasks += 1
            }
            
            // Wait for all remaining tasks to complete
            while let _ = try? await group.next() {
                completedTasks += 1
            }
            
            print("🎉 Completed image generation for \(completedTasks)/\(totalTasks) dishes")
        }
        
        // All tasks completed
        print("🎉 All image generation tasks completed")
        onComplete()
    }
    
    // MARK: - Private Methods
    
    private func generateImage(dishName: String, restaurantName: String?) async throws -> Data {
        // Check if API key is valid
        guard !geminiApiKey.isEmpty, geminiApiKey != "YOUR_GEMINI_API_KEY" else {
            print("❌ Gemini API key not configured")
            throw ImageGenerationError.apiError("Gemini API key not configured")
        }
        
        // Create the image generation prompt
        let prompt = createGenerationPrompt(dishName: dishName, restaurantName: restaurantName)
        
        // Prepare the request body for image generation
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["IMAGE", "TEXT"],
                "temperature": 0.7,
                "topK": 1,
                "topP": 0.9,
                "maxOutputTokens": 2048
            ]
        ]
        
        // Retry logic for transient server errors
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await performImageGenerationRequest(requestBody: requestBody)
            } catch let error as ImageGenerationError {
                // Check if it's a retryable error (500 Internal Server Error)
                if case .apiError(let message) = error, message.contains("status 500") {
                    lastError = error
                    if attempt < maxRetries {
                        let backoffDelay = calculateExponentialBackoff(attempt: attempt)
                        print("⚠️ Gemini API 500 error on attempt \(attempt)/\(maxRetries), retrying in \(String(format: "%.1f", backoffDelay)) seconds...")
                        try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                        continue
                    }
                }
                throw error
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let backoffDelay = calculateExponentialBackoff(attempt: attempt)
                    print("⚠️ Unexpected error on attempt \(attempt)/\(maxRetries), retrying in \(String(format: "%.1f", backoffDelay)) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                    continue
                }
                throw error
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? ImageGenerationError.apiError("All retry attempts failed")
    }
    
    private func calculateExponentialBackoff(attempt: Int) -> Double {
        let baseDelay = 1.0 // Base delay in seconds
        let maxDelay = 30.0 // Maximum delay in seconds
        let multiplier = 2.0 // Exponential multiplier
        
        // Calculate exponential backoff: baseDelay * (multiplier ^ (attempt - 1))
        let exponentialDelay = baseDelay * pow(multiplier, Double(attempt - 1))
        
        // Add jitter (±25% random variation) to prevent thundering herd
        let jitter = exponentialDelay * 0.25 * (Double.random(in: -1.0...1.0))
        let delayWithJitter = exponentialDelay + jitter
        
        // Cap at maximum delay
        return min(delayWithJitter, maxDelay)
    }
    
    private func createGenerationPrompt(dishName: String, restaurantName: String?) -> String {
        let prompt = """
        Generate a representative image for restaurant "\(restaurantName ?? "unknown")" and dish "\(dishName)".
        Search the restaurant and it's dish online first.
        Then generate the dish's image based on the search result.
        The generated image should be realistic.
        """
        
        return prompt
    }
    
    private func parseImageResponse(_ data: Data) throws -> Data {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let candidates = json?["candidates"] as? [[String: Any]]
            let content = candidates?.first?["content"] as? [String: Any]
            let parts = content?["parts"] as? [[String: Any]]
            
            // Look for image data in the response
            for part in parts ?? [] {
                if let inlineData = part["inlineData"] as? [String: Any],
                   let imageData = inlineData["data"] as? String,
                   let decodedData = Data(base64Encoded: imageData) {
                    print("✅ Successfully extracted generated image data from Gemini response")
                    return decodedData
                }
            }
            
            // If no image data found, check for text response
            if parts?.first?["text"] != nil {
                // print("📄 Gemini text response: \(text)")
                throw ImageGenerationError.apiError("Gemini did not provide generated image data")
            }
            
            print("❌ No valid response structure found")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw Gemini Response: \(responseString)")
            }
            throw ImageGenerationError.apiError("Invalid Gemini API response structure")
            
        } catch {
            print("❌ Gemini JSON Parse Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw Gemini Response: \(responseString)")
            }
            throw ImageGenerationError.apiError("Failed to parse Gemini API response: \(error.localizedDescription)")
        }
    }
    
    private func performImageGenerationRequest(requestBody: [String: Any]) async throws -> Data {
        // Use the service's geminiApiKey property, which supports env/config fallback
        guard !geminiApiKey.isEmpty, geminiApiKey != "YOUR_GEMINI_API_KEY" else {
            throw ImageGenerationError.apiError("Gemini API key not configured")
        }
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent?key=\(geminiApiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🎨 Calling Gemini API to generate image...")
        print("🔑 API Key: \(String(geminiApiKey.prefix(10)))...")
        print("🌐 URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageGenerationError.apiError("Invalid HTTP response from Gemini API")
        }
        
        print("📡 Gemini HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Gemini API Error: \(errorMessage)")
            throw ImageGenerationError.apiError("Gemini API request failed with status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Parse the response to extract generated image data
        return try parseImageResponse(data)
    }
}

// MARK: - Secure Credential Management
extension ImageGenerationService {
    private static func loadGeminiAPIKey() -> String {
        // Priority order for loading Gemini API key:
        // 1. Environment variable (for production)
        // 2. Configuration file (for development)
        // 3. Default placeholder
        
        // Check environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }
        
        // Check configuration file
        if let configKey = loadFromConfigFile(key: "GEMINI_API_KEY") {
            return configKey
        }
        
        // Return placeholder for development
        return "YOUR_GEMINI_API_KEY"
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
enum ImageGenerationError: Error, LocalizedError {
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