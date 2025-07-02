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
        
        // TODO: Implement restaurant name extraction logic
        // This could use NLP or heuristics to identify restaurant names
        // For now, return a placeholder
        return "Sample Restaurant"
    }
    
    func extractDishes(from images: [UIImage]) async throws -> [Dish] {
        let texts = try await extractText(from: images)
        
        // TODO: Implement dish extraction logic
        // This would parse the text to identify dish names, prices, and sections
        // For now, return sample dishes
        return [
            Dish(name: "Margherita Pizza", section: "Main Course", price: "$18"),
            Dish(name: "Caesar Salad", section: "Appetizers", price: "$12"),
            Dish(name: "Tiramisu", section: "Desserts", price: "$8"),
            Dish(name: "Spaghetti Carbonara", section: "Main Course", price: "$16"),
            Dish(name: "Bruschetta", section: "Appetizers", price: "$10")
        ]
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

// MARK: - Text Processing Extensions
extension OCRProcessor {
    func parseMenuText(_ text: String) -> [Dish] {
        // TODO: Implement sophisticated menu parsing
        // This would:
        // 1. Identify section headers (Appetizers, Main Course, etc.)
        // 2. Extract dish names and prices
        // 3. Handle different menu formats
        
        let lines = text.components(separatedBy: .newlines)
        var dishes: [Dish] = []
        var currentSection: String?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty { continue }
            
            // Check if line is a section header
            if isSectionHeader(trimmedLine) {
                currentSection = trimmedLine
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
        let sectionKeywords = ["appetizers", "starters", "main course", "entrees", "desserts", "drinks", "beverages"]
        let lowercasedLine = line.lowercased()
        
        return sectionKeywords.contains { lowercasedLine.contains($0) }
    }
    
    private func parseDishLine(_ line: String, section: String?) -> Dish? {
        // TODO: Implement more sophisticated dish parsing
        // This is a basic implementation that looks for price patterns
        
        let pricePattern = #"\$(\d+(?:\.\d{2})?)"#
        let priceRegex = try? NSRegularExpression(pattern: pricePattern)
        
        if let match = priceRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            let priceRange = Range(match.range(at: 1), in: line)!
            let price = String(line[priceRange])
            
            // Remove price from dish name
            let dishName = line.replacingOccurrences(of: pricePattern, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !dishName.isEmpty {
                return Dish(name: dishName, section: section, price: "$\(price)")
            }
        }
        
        // If no price found, treat the whole line as dish name
        if !line.isEmpty {
            return Dish(name: line, section: section)
        }
        
        return nil
    }
} 