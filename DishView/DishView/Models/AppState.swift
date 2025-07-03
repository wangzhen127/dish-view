import SwiftUI
import Foundation

@MainActor
class AppState: ObservableObject {
    @Published var currentStep: WorkflowStep = .menuInput
    @Published var menuImages: [UIImage] = []
    @Published var restaurantName: String = ""
    @Published var dishes: [Dish] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var extractedMenuData: MenuData?
    @Published var lastProcessedImageCount: Int = 0
    @Published var lastProcessedImageHashes: [String] = []
    
    enum WorkflowStep: CaseIterable {
        case menuInput
        case menuExtraction
        case dishDisplay
    }
    
    func resetApp() {
        currentStep = .menuInput
        menuImages.removeAll()
        restaurantName = ""
        dishes.removeAll()
        isLoading = false
        errorMessage = nil
        extractedMenuData = nil
        lastProcessedImageCount = 0
        lastProcessedImageHashes.removeAll()
    }
    
    func addMenuImage(_ image: UIImage) {
        menuImages.append(image)
    }
    
    func removeMenuImage(at index: Int) {
        guard index < menuImages.count else { return }
        menuImages.remove(at: index)
    }
    
    func setRestaurantName(_ name: String) {
        restaurantName = name
    }
    
    func setExtractedMenuData(_ menuData: MenuData) {
        extractedMenuData = menuData
        restaurantName = menuData.restaurantName ?? ""
        dishes = menuData.dishes
        
        // Store the current image state for future comparison
        lastProcessedImageCount = menuImages.count
        lastProcessedImageHashes = generateImageHashes()
        
        print("💾 Stored image state for future comparison:")
        print("   Image count: \(lastProcessedImageCount)")
        print("   Hash count: \(lastProcessedImageHashes.count)")
    }
    
    private func generateImageHashes() -> [String] {
        return menuImages.compactMap { image in
            guard let data = image.jpegData(compressionQuality: 0.1) else { return nil }
            return data.base64EncodedString()
        }
    }
    
    func haveImagesChanged() -> Bool {
        print("🔍 Checking for image changes...")
        print("   Current image count: \(menuImages.count)")
        print("   Last processed image count: \(lastProcessedImageCount)")
        
        // Check if image count has changed
        if lastProcessedImageCount != menuImages.count {
            print("   ❌ Image count changed: \(lastProcessedImageCount) -> \(menuImages.count)")
            return true
        }
        
        // Check if any image content has changed
        let currentHashes = generateImageHashes()
        print("   Current hashes count: \(currentHashes.count)")
        print("   Last processed hashes count: \(lastProcessedImageHashes.count)")
        
        if currentHashes.count != lastProcessedImageHashes.count {
            print("   ❌ Hash count mismatch")
            return true
        }
        
        // Compare hashes
        for (index, hash) in currentHashes.enumerated() {
            if index >= lastProcessedImageHashes.count || hash != lastProcessedImageHashes[index] {
                print("   ❌ Hash mismatch at index \(index)")
                return true
            }
        }
        
        print("   ✅ No image changes detected")
        return false
    }
    
    func addDish(_ dish: Dish) {
        dishes.append(dish)
    }
    
    func updateDish(_ dish: Dish, at index: Int) {
        guard index < dishes.count else { return }
        dishes[index] = dish
    }
    
    func removeDish(at index: Int) {
        guard index < dishes.count else { return }
        dishes.remove(at: index)
    }
} 