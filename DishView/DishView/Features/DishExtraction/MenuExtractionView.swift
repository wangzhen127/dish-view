import SwiftUI

struct MenuExtractionView: View {
    @ObservedObject var appState: AppState
    @State private var restaurantName: String = ""
    @State private var extractedDishes: [Dish] = []
    @State private var isExtracting: Bool = true
    @State private var extractionError: String?
    @State private var showingEditSheet = false
    @State private var editingDish: Dish?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isExtracting {
                    Spacer()
                    
                    LoadingIndicator("Extracting restaurant name and dishes...")
                    
                    Spacer()
                } else if let error = extractionError {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Extraction Failed")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            extractMenuData()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Restaurant Name Section (Read-only)
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.blue)
                                    Text("Restaurant Name")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                if !restaurantName.isEmpty {
                                    Text(restaurantName)
                                        .font(.body)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.systemGray6))
                                        )
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Restaurant name confirmed")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 30))
                                            .foregroundColor(.orange)
                                        
                                        Text("Restaurant Name Not Found")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("We couldn't extract the restaurant name from your menu images. Please go back and upload clearer photos of the menu.")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                        
                                        Button("Go Back") {
                                            appState.currentStep = .menuInput
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            
                            // Dishes Section
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "fork.knife")
                                        .foregroundColor(.blue)
                                    Text("Extracted Dishes")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(extractedDishes.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.systemGray5))
                                        )
                                }
                                
                                if !extractedDishes.isEmpty {
                                    LazyVStack(spacing: 12) {
                                        ForEach(Array(extractedDishes.enumerated()), id: \.offset) { index, dish in
                                            DishExtractionCard(
                                                dish: dish,
                                                onEdit: {
                                                    editingDish = dish
                                                    showingEditSheet = true
                                                },
                                                onDelete: {
                                                    extractedDishes.remove(at: index)
                                                }
                                            )
                                        }
                                    }
                                } else {
                                    EmptyStateView(
                                        icon: "fork.knife",
                                        title: "No Dishes Found",
                                        message: "We couldn't extract any dishes from the menu images. Please try with clearer photos."
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .padding()
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        PrimaryButton(
                            "Continue",
                            isDisabled: restaurantName.isEmpty || extractedDishes.isEmpty
                        ) {
                            appState.setRestaurantName(restaurantName)
                            appState.dishes = extractedDishes
                            appState.currentStep = .dishDisplay
                        }
                        
                        Button("Back") {
                            appState.currentStep = .menuInput
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                }
                // Add Re-extract button
                Button(action: {
                    // Clear cached extraction and force re-extract
                    appState.extractedMenuData = nil
                    isExtracting = true
                    extractMenuData()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-extract Names")
                    }
                }
                .padding(.top, 8)
                .disabled(isExtracting)
            }
            .navigationTitle("Menu Extraction")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let cached = appState.extractedMenuData {
                    // Check if images have changed since last extraction
                    if appState.haveImagesChanged() {
                        print("🔄 Images have changed, re-extracting menu data")
                        extractMenuData()
                    } else {
                        print("✅ Using cached menu data - no image changes detected")
                        // Use cached data, skip API call
                        restaurantName = cached.restaurantName ?? ""
                        extractedDishes = cached.dishes
                        isExtracting = false
                    }
                } else {
                    print("🆕 No cached data available, extracting menu data")
                    extractMenuData()
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let dish = editingDish {
                    DishEditView(dish: dish) { updatedDish in
                        if let index = extractedDishes.firstIndex(where: { $0.id == dish.id }) {
                            extractedDishes[index] = updatedDish
                        }
                    }
                }
            }
        }
    }
    
    private func extractMenuData() {
        guard !appState.menuImages.isEmpty else {
            extractionError = "No menu images available for extraction."
            isExtracting = false
            return
        }
        
        isExtracting = true
        extractionError = nil
        
        Task {
            do {
                let menuData = try await OCRProcessor.shared.extractMenuData(from: appState.menuImages)
                
                await MainActor.run {
                    // Store the complete menu data for reuse
                    appState.setExtractedMenuData(menuData)
                    
                    // Set the UI state
                    if let name = menuData.restaurantName, !name.isEmpty {
                        restaurantName = name
                    } else {
                        restaurantName = ""
                    }
                    
                    extractedDishes = menuData.dishes
                    isExtracting = false
                }
            } catch {
                await MainActor.run {
                    extractionError = "Failed to extract menu data: \(error.localizedDescription)"
                    isExtracting = false
                }
            }
        }
    }
}

#Preview {
    MenuExtractionView(appState: AppState())
} 