import SwiftUI

struct DishGridView: View {
    @ObservedObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedSection: String?
    @State private var isDownloadingImages = false
    @State private var downloadedDishes: [Dish] = []
    
    var filteredDishes: [Dish] {
        var dishes = downloadedDishes.isEmpty ? appState.dishes : downloadedDishes
        
        if !searchText.isEmpty {
            dishes = dishes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let section = selectedSection {
            dishes = dishes.filter { $0.section == section }
        }
        
        return dishes
    }
    
    var sections: [String] {
        Array(Set(appState.dishes.compactMap { $0.section })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header (more compact)
                VStack(spacing: 4) {
                    Text(appState.restaurantName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 0)
                    
                    Text("\(filteredDishes.count) dishes found")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                .padding(.bottom, 0)
                
                // Search and Filter
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search dishes...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    if !sections.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(
                                    title: "All",
                                    isSelected: selectedSection == nil
                                ) {
                                    selectedSection = nil
                                }
                                
                                ForEach(sections, id: \.self) { section in
                                    FilterChip(
                                        title: section,
                                        isSelected: selectedSection == section
                                    ) {
                                        selectedSection = section
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Dish Grid
                if isDownloadingImages && downloadedDishes.isEmpty {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Searching for dish images...")
                            .font(.headline)
                        
                        Text("This may take a few moments")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                } else if !filteredDishes.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredDishes) { dish in
                                DishCardView(dish: dish, restaurantName: appState.restaurantName.isEmpty ? nil : appState.restaurantName)
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Dishes Found",
                        message: searchText.isEmpty ? "No dishes available to display." : "No dishes match your search."
                    )
                    
                    Spacer()
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    PrimaryButton("Start Over") {
                        appState.resetApp()
                    }
                    
                    Button("Back") {
                        appState.currentStep = .menuExtraction
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Dish View")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("📱 DishGridView appeared")
                print("📊 downloadedDishes.count: \(downloadedDishes.count)")
                print("📊 appState.dishes.count: \(appState.dishes.count)")
                print("📊 isDownloadingImages: \(isDownloadingImages)")
                
                if downloadedDishes.isEmpty && !appState.dishes.isEmpty {
                    print("🚀 Triggering image download")
                    downloadImagesForDishes()
                } else {
                    print("⏭️ Skipping image download - already downloaded or no dishes")
                }
            }
        }
    }
    
    private func downloadImagesForDishes() {
        guard !appState.dishes.isEmpty else { 
            print("❌ No dishes to download images for")
            return 
        }
        
        print("🔄 Setting isDownloadingImages = true")
        isDownloadingImages = true
        
        Task {
            print("🖼️ Starting image download for \(appState.dishes.count) dishes")
            print("🏪 Restaurant name: '\(appState.restaurantName.isEmpty ? "empty" : appState.restaurantName)'")
            
            let updatedDishes = await ImageSearchService.shared.searchDishImages(
                for: appState.dishes,
                restaurantName: appState.restaurantName.isEmpty ? nil : appState.restaurantName
            )
            
            await MainActor.run {
                downloadedDishes = updatedDishes
                isDownloadingImages = false
                
                let successCount = updatedDishes.filter { $0.image != nil }.count
                print("✅ Image download completed: \(successCount)/\(updatedDishes.count) dishes have images")
                print("🔄 Setting isDownloadingImages = false")
                
                // Debug: Verify dish matching
                print("🔍 Verifying dish matching in DishGridView:")
                for (index, dish) in updatedDishes.enumerated() {
                    print("  Dish \(index + 1): '\(dish.name)' (ID: \(dish.id)) - Has image: \(dish.image != nil)")
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let appState = AppState()
    // For preview, use an empty AppState. Real data comes from extraction.
    return DishGridView(appState: appState)
} 