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
        print("🍽️ Starting progressive image generation for \(dishes.count) dishes")
        if let restaurantName = restaurantName {
            print("🏪 Restaurant: \(restaurantName)")
        }
        
        // Process dishes sequentially to avoid rate limiting
        for dish in dishes {
            print("🎨 Starting image generation for dish: '\(dish.name)' (ID: \(dish.id))")
            
            var updatedDish = dish
            updatedDish.isImageLoading = true
            updatedDish.imageLoadError = false
            updatedDish.image = nil
            
            // Notify that we're starting to load this dish
            onDishUpdated(updatedDish)
            
            do {
                if let image = try await self.generateDishImage(dishName: dish.name, restaurantName: restaurantName) {
                    print("✅ Generated image for '\(dish.name)' (ID: \(dish.id))")
                    updatedDish.image = image
                    updatedDish.imageLoadError = false
                } else {
                    print("❌ No image generated for '\(dish.name)' (ID: \(dish.id))")
                    updatedDish.imageLoadError = true
                }
            } catch {
                print("💥 Error generating image for '\(dish.name)' (ID: \(dish.id)): \(error)")
                updatedDish.imageLoadError = true
            }
            
            updatedDish.isImageLoading = false
            
            // Notify that this dish is complete
            onDishUpdated(updatedDish)
            
            // Add a small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        // All tasks completed
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
        
        // Construct the URL
        guard let url = URL(string: "\(baseURL)?key=\(geminiApiKey)") else {
            throw ImageGenerationError.invalidURL
        }
        
        // Prepare the request body following the official documentation
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["TEXT", "IMAGE"],
                "temperature": 0.5,
                "topK": 1,
                "topP": 0.9,
                "maxOutputTokens": 4096
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120.0 // Longer timeout for combined operation
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
    
    private func createGenerationPrompt(dishName: String, restaurantName: String?) -> String {
        var prompt = """
        Generate a representative image for restaurant "\(restaurantName)" and dish "\(dishName)".
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
            if let text = parts?.first?["text"] as? String {
                print("📄 Gemini text response: \(text)")
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