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
    
    enum WorkflowStep: CaseIterable {
        case menuInput
        case restaurantConfirmation
        case dishExtraction
        case dishDisplay
    }
    
    func resetApp() {
        currentStep = .menuInput
        menuImages.removeAll()
        restaurantName = ""
        dishes.removeAll()
        isLoading = false
        errorMessage = nil
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