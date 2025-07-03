import Foundation
import UIKit

class OCRProcessor: ObservableObject {
    static let shared = OCRProcessor()
    
    private let geminiService = GeminiService()
    
    private init() {}
    
    // MARK: - Main Extraction Methods
    
    func extractText(from images: [UIImage]) async throws -> [String] {
        var extractedTexts: [String] = []
        
        for image in images {
            let text = try await extractTextFromImage(image)
            extractedTexts.append(text)
        }
        
        return extractedTexts
    }
    
    func extractRestaurantName(from images: [UIImage]) async throws -> String? {
        // This function is now deprecated - use extractMenuData instead
        let menuData = try await extractMenuData(from: images)
        return menuData.restaurantName
    }
    
    func extractDishes(from images: [UIImage]) async throws -> [Dish] {
        // This function is now deprecated - use extractMenuData instead
        let menuData = try await extractMenuData(from: images)
        return menuData.dishes
    }
    
    func extractMenuData(from images: [UIImage]) async throws -> MenuData {
        guard let firstImage = images.first else {
            throw OCRError.invalidImage
        }
        
        print("Extracting restaurant name and dishes from image with size: \(firstImage.size)")
        
        let prompt = """
        Analyze this restaurant menu image and extract both the restaurant name and all dishes with their sections and prices.
        
        Return the data in this exact JSON format:
        {
            "restaurantName": "Restaurant Name",
            "dishes": [
                {
                    "name": "Dish Name",
                    "section": "Section Name (e.g., Appetizers, Main Course, Desserts)",
                    "price": "$XX.XX"
                }
            ]
        }
        
        Rules:
        - Extract the restaurant name from the top of the menu
        - Extract only actual dishes, not section headers
        - Include prices if available
        - Group dishes by their sections
        - Clean up dish names (remove special characters, extra spaces)
        - If no price is found, set price to null
        - If no clear restaurant name is found, set restaurantName to null
        """
        
        let jsonResponse = try await geminiService.analyzeImage(firstImage, prompt: prompt)
        return parseMenuDataFromJSON(jsonResponse)
    }
    
    // MARK: - Gemini Integration
    
    private func extractTextFromImage(_ image: UIImage) async throws -> String {
        let prompt = """
        Extract all text from this image in the exact order it appears.
        Return only the raw text, maintaining line breaks and spacing.
        Do not add any interpretation or formatting.
        """
        
        return try await geminiService.analyzeImage(image, prompt: prompt) ?? ""
    }
    
    private func parseDishesFromJSON(_ jsonString: String?) -> [Dish] {
        guard let jsonString = jsonString else {
            return []
        }
        
        // Clean up the JSON string - remove markdown code blocks if present
        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks (```json ... ```)
        if cleanJSON.hasPrefix("```json") {
            cleanJSON = String(cleanJSON.dropFirst(7)) // Remove "```json"
        }
        if cleanJSON.hasPrefix("```") {
            cleanJSON = String(cleanJSON.dropFirst(3)) // Remove "```"
        }
        if cleanJSON.hasSuffix("```") {
            cleanJSON = String(cleanJSON.dropLast(3)) // Remove "```"
        }
        
        cleanJSON = cleanJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanJSON.data(using: .utf8) else {
            print("Failed to convert JSON string to data")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(DishResponse.self, from: data)
            print("Successfully parsed \(response.dishes.count) dishes")
            return response.dishes
        } catch {
            print("Failed to parse dishes JSON: \(error)")
            print("Cleaned JSON: \(cleanJSON)")
            return []
        }
    }
    
    private func parseMenuDataFromJSON(_ jsonString: String?) -> MenuData {
        guard let jsonString = jsonString else {
            return MenuData(restaurantName: nil, dishes: [])
        }
        
        // Clean up the JSON string - remove markdown code blocks if present
        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks (```json ... ```)
        if cleanJSON.hasPrefix("```json") {
            cleanJSON = String(cleanJSON.dropFirst(7)) // Remove "```json"
        }
        if cleanJSON.hasPrefix("```") {
            cleanJSON = String(cleanJSON.dropFirst(3)) // Remove "```"
        }
        if cleanJSON.hasSuffix("```") {
            cleanJSON = String(cleanJSON.dropLast(3)) // Remove "```"
        }
        
        cleanJSON = cleanJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanJSON.data(using: .utf8) else {
            print("Failed to convert JSON string to data")
            return MenuData(restaurantName: nil, dishes: [])
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(MenuDataResponse.self, from: data)
            print("Successfully parsed restaurant: '\(response.restaurantName ?? "nil")' and \(response.dishes.count) dishes")
            return MenuData(restaurantName: response.restaurantName, dishes: response.dishes)
        } catch {
            print("Failed to parse menu data JSON: \(error)")
            print("Cleaned JSON: \(cleanJSON)")
            return MenuData(restaurantName: nil, dishes: [])
        }
    }
}

// MARK: - Gemini Service

class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    init() {
        // Load API key from configuration
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let geminiKey = config["GEMINI_API_KEY"] as? String else {
            fatalError("GEMINI_API_KEY not found in Config.plist")
        }
        self.apiKey = geminiKey
    }
    
    func analyzeImage(_ image: UIImage, prompt: String) async throws -> String? {
        // Get image data in original format or best available format
        let (imageData, mimeType) = try getImageDataAndMimeType(image)
        
        print("Using image format: \(mimeType), size: \(imageData.count) bytes")
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": mimeType,
                                "data": base64Image
                            ]
                        ],
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topK": 1,
                "topP": 1,
                "maxOutputTokens": 2048
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw OCRError.processingError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OCRError.processingError("Failed to serialize request: \(error.localizedDescription)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OCRError.processingError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("API request failed with status: \(httpResponse.statusCode), body: \(errorBody)")
            throw OCRError.processingError("API request failed with status: \(httpResponse.statusCode)")
        }
        
        return try parseGeminiResponse(data)
    }
    
    private func getImageDataAndMimeType(_ image: UIImage) throws -> (Data, String) {
        // Try PNG first (lossless, good for text/images with sharp edges)
        if let pngData = image.pngData() {
            return (pngData, "image/png")
        }
        
        // Fallback to JPEG if PNG fails
        if let jpegData = image.jpegData(compressionQuality: 0.9) {
            return (jpegData, "image/jpeg")
        }
        
        // Try the extension method as last resort
        if let extensionData = image.toJPEGData(compressionQuality: 0.9) {
            return (extensionData, "image/jpeg")
        }
        
        print("Failed to convert image to any supported format")
        throw OCRError.invalidImage
    }
    
    private func parseGeminiResponse(_ data: Data) throws -> String? {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            // Check for API errors first
            if let error = json?["error"] as? [String: Any] {
                let errorMessage = error["message"] as? String ?? "Unknown API error"
                print("Gemini API error: \(errorMessage)")
                throw OCRError.processingError("API Error: \(errorMessage)")
            }
            
            guard let candidates = json?["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("Failed to parse Gemini response structure")
                print("Response JSON: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                return nil
            }
            
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            print("Parsed Gemini response: \(trimmedText)")
            return trimmedText
        } catch {
            print("Failed to parse Gemini response: \(error)")
            throw error
        }
    }
}

// MARK: - Data Models

struct DishResponse: Codable {
    let dishes: [Dish]
}

struct MenuDataResponse: Codable {
    let restaurantName: String?
    let dishes: [Dish]
}

struct MenuData {
    let restaurantName: String?
    let dishes: [Dish]
}

// MARK: - Error Types

enum OCRError: Error {
    case invalidImage
    case noTextFound
    case processingError(String)
} 