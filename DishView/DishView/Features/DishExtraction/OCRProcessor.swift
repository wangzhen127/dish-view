import Foundation
import UIKit
import Vision

class OCRProcessor: ObservableObject {
    static let shared = OCRProcessor()
    
    private init() {}
    
    func extractText(from images: [UIImage]) async throws -> [String] {
        var extractedTexts: [String] = []
        
        for image in images {
            let text = try await performOCR(on: image)
            extractedTexts.append(text)
        }
        
        return extractedTexts
    }
    
    func extractRestaurantName(from images: [UIImage]) async throws -> String? {
        let texts = try await extractText(from: images)
        
        // Combine all extracted texts
        let combinedText = texts.joined(separator: "\n")
        
        // Try multiple strategies to extract restaurant name
        if let restaurantName = extractRestaurantNameFromText(combinedText) {
            return restaurantName
        }
        
        // If no restaurant name found, return nil
        return nil
    }
    
    func extractDishes(from images: [UIImage]) async throws -> [Dish] {
        let texts = try await extractText(from: images)
        
        // Combine all texts and parse for dishes
        let combinedText = texts.joined(separator: "\n")
        return parseMenuText(combinedText)
    }
    
    private func performOCR(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error))
            }
        }
    }
}

// MARK: - Error Types
enum OCRError: Error {
    case invalidImage
    case noTextFound
    case visionError(Error)
    case processingError(String)
}

// MARK: - Restaurant Name Extraction
extension OCRProcessor {
    private func extractRestaurantNameFromText(_ text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        
        // Strategy 1: Look for restaurant name in the first few lines (header area)
        for i in 0..<min(5, lines.count) {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if let restaurantName = extractRestaurantNameFromLine(line) {
                return restaurantName
            }
        }
        
        // Strategy 2: Look for common restaurant name patterns throughout the text
        if let restaurantName = findRestaurantNamePatterns(in: text) {
            return restaurantName
        }
        
        // Strategy 3: Look for text that appears to be a restaurant name based on formatting
        if let restaurantName = findFormattedRestaurantName(in: lines) {
            return restaurantName
        }
        
        return nil
    }
    
    private func extractRestaurantNameFromLine(_ line: String) -> String? {
        // Skip empty lines and common menu words
        if line.isEmpty || isCommonMenuWord(line) {
            return nil
        }
        
        // Look for lines that are likely restaurant names
        let cleanedLine = cleanRestaurantName(line)
        
        // Check if the line looks like a restaurant name
        if isValidRestaurantName(cleanedLine) {
            return cleanedLine
        }
        
        return nil
    }
    
    private func findRestaurantNamePatterns(in text: String) -> String? {
        // Common restaurant name patterns
        let patterns = [
            #"^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:Restaurant|Cafe|Bistro|Grill|Pizzeria|Diner|Bar|Kitchen|House|Place|Corner|Spot))"#,
            #"^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:&|and)\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#,
            #"^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range) {
                    let matchRange = Range(match.range(at: 1), in: text)!
                    let restaurantName = String(text[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if isValidRestaurantName(restaurantName) {
                        return restaurantName
                    }
                }
            }
        }
        
        return nil
    }
    
    private func findFormattedRestaurantName(in lines: [String]) -> String? {
        // Look for lines that are centered, bold, or have special formatting
        for line in lines.prefix(10) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip if too short or too long
            if trimmedLine.count < 3 || trimmedLine.count > 50 {
                continue
            }
            
            // Check if line has characteristics of a restaurant name
            if isLikelyRestaurantName(trimmedLine) {
                return cleanRestaurantName(trimmedLine)
            }
        }
        
        return nil
    }
    
    private func isCommonMenuWord(_ text: String) -> Bool {
        let commonWords = [
            "menu", "appetizers", "starters", "main course", "entrees", "desserts",
            "drinks", "beverages", "wine", "beer", "cocktails", "specials",
            "daily", "chef", "house", "signature", "popular", "favorites"
        ]
        
        let lowercasedText = text.lowercased()
        return commonWords.contains { lowercasedText.contains($0) }
    }
    
    private func isValidRestaurantName(_ name: String) -> Bool {
        // Must be at least 3 characters
        if name.count < 3 {
            return false
        }
        
        // Must not be too long
        if name.count > 50 {
            return false
        }
        
        // Must contain letters
        if !name.contains(where: { $0.isLetter }) {
            return false
        }
        
        // Must not be all uppercase (likely a section header)
        if name == name.uppercased() && name.count > 5 {
            return false
        }
        
        // Must not contain only numbers
        if name.rangeOfCharacter(from: CharacterSet.letters) == nil {
            return false
        }
        
        return true
    }
    
    private func isLikelyRestaurantName(_ text: String) -> Bool {
        // Check for characteristics of restaurant names
        let words = text.components(separatedBy: .whitespaces)
        
        // Should have 1-4 words typically
        if words.count < 1 || words.count > 4 {
            return false
        }
        
        // First word should start with capital letter
        if let firstWord = words.first, !firstWord.isEmpty {
            if !firstWord.first!.isUppercase {
                return false
            }
        }
        
        // Should not contain common menu section words
        if isCommonMenuWord(text) {
            return false
        }
        
        // Should not contain price patterns
        if text.contains("$") || text.range(of: #"\d+"#, options: .regularExpression) != nil {
            return false
        }
        
        return true
    }
    
    private func cleanRestaurantName(_ name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common suffixes that might be OCR artifacts
        let suffixesToRemove = ["restaurant", "cafe", "bistro", "grill", "pizzeria", "diner", "bar", "kitchen", "house", "place", "corner", "spot"]
        
        for suffix in suffixesToRemove {
            if cleaned.lowercased().hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        // Remove extra whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return cleaned
    }
}

// MARK: - Text Processing Extensions
extension OCRProcessor {
    func parseMenuText(_ text: String) -> [Dish] {
        let lines = text.components(separatedBy: .newlines)
        var dishes: [Dish] = []
        var currentSection: String?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty { continue }
            
            // Check if line is a section header
            if isSectionHeader(trimmedLine) {
                currentSection = cleanSectionName(trimmedLine)
                continue
            }
            
            // Try to extract dish information
            if let dish = parseDishLine(trimmedLine, section: currentSection) {
                dishes.append(dish)
            }
        }
        
        return dishes
    }
    
    private func isSectionHeader(_ line: String) -> Bool {
        let sectionKeywords = [
            "appetizers", "starters", "first course", "small plates",
            "main course", "entrees", "main dishes", "mains",
            "desserts", "sweets", "pastries", "ice cream",
            "drinks", "beverages", "cocktails", "wine", "beer",
            "sides", "side dishes", "vegetables", "salads",
            "soups", "sandwiches", "burgers", "pizza", "pasta"
        ]
        
        let lowercasedLine = line.lowercased()
        
        // Check for exact matches or contains
        for keyword in sectionKeywords {
            if lowercasedLine == keyword || lowercasedLine.contains(keyword) {
                return true
            }
        }
        
        // Check for all caps (common for section headers)
        if line == line.uppercased() && line.count > 3 && line.count < 20 {
            return true
        }
        
        return false
    }
    
    private func cleanSectionName(_ section: String) -> String {
        var cleaned = section.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Convert to title case
        cleaned = cleaned.capitalized
        
        // Handle common variations
        let sectionMappings = [
            "appetizers": "Appetizers",
            "starters": "Appetizers",
            "first course": "Appetizers",
            "small plates": "Appetizers",
            "main course": "Main Course",
            "entrees": "Main Course",
            "main dishes": "Main Course",
            "mains": "Main Course",
            "desserts": "Desserts",
            "sweets": "Desserts",
            "pastries": "Desserts",
            "drinks": "Beverages",
            "beverages": "Beverages",
            "cocktails": "Beverages",
            "wine": "Beverages",
            "beer": "Beverages"
        ]
        
        return sectionMappings[cleaned.lowercased()] ?? cleaned
    }
    
    private func parseDishLine(_ line: String, section: String?) -> Dish? {
        // Skip if line is too short or likely a header
        if line.count < 3 || isSectionHeader(line) {
            return nil
        }
        
        // Try to extract price first
        let pricePatterns = [
            #"\$(\d+(?:\.\d{2})?)"#,           // $12.99
            #"(\d+(?:\.\d{2})?)\s*\$"#,        // 12.99$
            #"(\d+(?:\.\d{2})?)\s*(?:dollars|USD)"#, // 12.99 dollars
            #"(\d+(?:\.\d{2})?)\s*€"#,         // 12.99€
            #"€\s*(\d+(?:\.\d{2})?)"#,         // €12.99
            #"(\d+(?:\.\d{2})?)\s*£"#,         // 12.99£
            #"£\s*(\d+(?:\.\d{2})?)"#          // £12.99
        ]
        
        var extractedPrice: String?
        var dishName = line
        
        for pattern in pricePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(line.startIndex..., in: line)
                if let match = regex.firstMatch(in: line, range: range) {
                    let priceRange = Range(match.range(at: 1), in: line)!
                    let price = String(line[priceRange])
                    
                    // Format price consistently
                    if let priceDouble = Double(price) {
                        extractedPrice = String(format: "$%.2f", priceDouble)
                    }
                    
                    // Remove price from dish name
                    dishName = regex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
                    break
                }
            }
        }
        
        // Clean up dish name
        dishName = cleanDishName(dishName)
        
        // Validate dish name
        if isValidDishName(dishName) {
            return Dish(name: dishName, section: section, price: extractedPrice)
        }
        
        return nil
    }
    
    private func cleanDishName(_ name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common menu artifacts
        let artifacts = ["*", "•", "→", "→", "—", "-", "|", "/", "\\"]
        for artifact in artifacts {
            cleaned = cleaned.replacingOccurrences(of: artifact, with: " ")
        }
        
        // Remove extra whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Capitalize first letter of each word
        cleaned = cleaned.capitalized
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isValidDishName(_ name: String) -> Bool {
        // Must be at least 2 characters
        if name.count < 2 {
            return false
        }
        
        // Must not be too long
        if name.count > 100 {
            return false
        }
        
        // Must contain letters
        if !name.contains(where: { $0.isLetter }) {
            return false
        }
        
        // Must not be all uppercase (likely a section header)
        if name == name.uppercased() && name.count > 10 {
            return false
        }
        
        // Must not contain only numbers or special characters
        if name.rangeOfCharacter(from: CharacterSet.letters) == nil {
            return false
        }
        
        return true
    }
} 