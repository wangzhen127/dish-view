import SwiftUI

struct DishGridView: View {
    @ObservedObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedSection: String?
    
    var filteredDishes: [Dish] {
        var dishes = appState.dishes
        
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
                // Header
                VStack(spacing: 12) {
                    Text(appState.restaurantName)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("\(filteredDishes.count) dishes found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
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
                if !filteredDishes.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredDishes) { dish in
                                DishCardView(dish: dish)
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
                        appState.currentStep = .dishExtraction
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Dish View")
            .navigationBarTitleDisplayMode(.inline)
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