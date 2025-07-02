import SwiftUI

struct DishExtractionView: View {
    @ObservedObject var appState: AppState
    @State private var extractedDishes: [Dish] = []
    @State private var isExtracting: Bool = true
    @State private var extractionError: String?
    @State private var showingEditSheet = false
    @State private var editingDish: Dish?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Extract Dishes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Review and edit the dishes extracted from your menu")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if isExtracting {
                    Spacer()
                    
                    LoadingIndicator("Extracting dishes from menu...")
                    
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
                            extractDishes()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    // Dish List
                    if !extractedDishes.isEmpty {
                        ScrollView {
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
                            .padding()
                        }
                    } else {
                        Spacer()
                        
                        EmptyStateView(
                            icon: "fork.knife",
                            title: "No Dishes Found",
                            message: "We couldn't extract any dishes from the menu images. Please try with clearer photos."
                        )
                        
                        Spacer()
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        PrimaryButton(
                            "Continue",
                            isDisabled: extractedDishes.isEmpty
                        ) {
                            appState.dishes = extractedDishes
                            appState.currentStep = .dishDisplay
                        }
                        
                        Button("Back") {
                            appState.currentStep = .restaurantConfirmation
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Dish Extraction")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                extractDishes()
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
    
    private func extractDishes() {
        guard !appState.menuImages.isEmpty else {
            extractionError = "No menu images available for extraction."
            isExtracting = false
            return
        }
        
        isExtracting = true
        extractionError = nil
        
        Task {
            do {
                let dishes = try await OCRProcessor.shared.extractDishes(from: appState.menuImages)
                
                await MainActor.run {
                    extractedDishes = dishes
                    isExtracting = false
                }
            } catch {
                await MainActor.run {
                    extractionError = "Failed to extract dishes: \(error.localizedDescription)"
                    isExtracting = false
                }
            }
        }
    }
}

struct DishExtractionCard: View {
    let dish: Dish
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let section = dish.section {
                    Text(section)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let price = dish.price {
                    Text(price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct DishEditView: View {
    @Environment(\.dismiss) private var dismiss
    let dish: Dish
    let onSave: (Dish) -> Void
    
    @State private var name: String
    @State private var section: String
    @State private var price: String
    
    init(dish: Dish, onSave: @escaping (Dish) -> Void) {
        self.dish = dish
        self.onSave = onSave
        self._name = State(initialValue: dish.name)
        self._section = State(initialValue: dish.section ?? "")
        self._price = State(initialValue: dish.price ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Dish Information") {
                    TextField("Dish Name", text: $name)
                    TextField("Section (e.g., Appetizers)", text: $section)
                    TextField("Price", text: $price)
                }
            }
            .navigationTitle("Edit Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedDish = dish
                        updatedDish.name = name
                        updatedDish.section = section.isEmpty ? nil : section
                        updatedDish.price = price.isEmpty ? nil : price
                        onSave(updatedDish)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    DishExtractionView(appState: AppState())
} 