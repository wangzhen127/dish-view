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
        guard let firstImage = images.first else {
            throw OCRError.invalidImage
        }
        
        let prompt = """
        Analyze this restaurant menu image and extract the restaurant name.
        Look for the restaurant name typically found at the top of the menu.
        Return only the restaurant name, nothing else.
        If no clear restaurant name is found, return null.
        """
        
        return try await geminiService.analyzeImage(firstImage, prompt: prompt)
    }
    
    func extractDishes(from images: [UIImage]) async throws -> [Dish] {
        guard let firstImage = images.first else {
            throw OCRError.invalidImage
        }
        
        let prompt = """
        Analyze this restaurant menu image and extract all dishes with their sections and prices.
        Return the data in this exact JSON format:
        {
            "dishes": [
                {
                    "name": "Dish Name",
                    "section": "Section Name (e.g., Appetizers, Main Course, Desserts)",
                    "price": "$XX.XX"
                }
            ]
        }
        
        Rules:
        - Extract only actual dishes, not section headers
        - Include prices if available
        - Group dishes by their sections
        - Clean up dish names (remove special characters, extra spaces)
        - If no price is found, set price to null
        """
        
        let jsonResponse = try await geminiService.analyzeImage(firstImage, prompt: prompt)
        return parseDishesFromJSON(jsonResponse)
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
        guard let jsonString = jsonString,
              let data = jsonString.data(using: .utf8) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(DishResponse.self, from: data)
            return response.dishes
        } catch {
            print("Failed to parse dishes JSON: \(error)")
            return []
        }
    }
}

// MARK: - Gemini Service

class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent"
    
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
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw OCRError.invalidImage
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
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
            throw OCRError.processingError("API request failed with status: \(httpResponse.statusCode)")
        }
        
        return parseGeminiResponse(data)
    }
    
    private func parseGeminiResponse(_ data: Data) -> String? {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let candidates = json?["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                return nil
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Failed to parse Gemini response: \(error)")
            return nil
        }
    }
}

// MARK: - Data Models

struct DishResponse: Codable {
    let dishes: [Dish]
}

// MARK: - Error Types

enum OCRError: Error {
    case invalidImage
    case noTextFound
    case processingError(String)
} 