import SwiftUI

struct DishCardView: View {
    let dish: Dish
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Dish Image
                ZStack {
                    if let image = dish.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                    } else if dish.isImageLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(height: 120)
                    } else if dish.imageLoadError {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .frame(height: 120)
                            .background(Color(.systemGray5))
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .frame(height: 120)
                            .background(Color(.systemGray5))
                    }
                }
                .cornerRadius(12)
                
                // Dish Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dish.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let section = dish.section {
                        Text(section)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let price = dish.price {
                        Text(price)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            DishDetailView(dish: dish)
        }
    }
}

struct DishDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRetryingImage = false
    @State private var updatedDish: Dish
    
    let dish: Dish
    let onRetryImage: ((Dish) -> Void)?
    
    init(dish: Dish, onRetryImage: ((Dish) -> Void)? = nil) {
        self.dish = dish
        self.onRetryImage = onRetryImage
        self._updatedDish = State(initialValue: dish)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Dish Image
                    if let image = updatedDish.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(16)
                    } else if updatedDish.isImageLoading || isRetryingImage {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                            Text(isRetryingImage ? "Retrying..." : "Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 100))
                            .foregroundColor(.secondary)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                    }
                    
                    // Dish Information
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text(updatedDish.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            if let section = updatedDish.section {
                                Text(section)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let price = updatedDish.price {
                            Text(price)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        if let description = updatedDish.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Action Button
                        Button(action: {
                            retryImageSearch()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry Image Search")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .foregroundColor(.blue)
                        }
                        .disabled(isRetryingImage)
                        .padding(.horizontal)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Dish Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }

        }
    }
    
    // MARK: - Private Methods
    
    private func retryImageSearch() {
        guard !isRetryingImage else { return }
        
        isRetryingImage = true
        
        Task {
            do {
                // Create a new dish instance for retry
                var retryDish = updatedDish
                retryDish.isImageLoading = true
                retryDish.imageLoadError = false
                retryDish.image = nil
                
                // Update the UI immediately
                await MainActor.run {
                    updatedDish = retryDish
                }
                
                // Attempt to search for the image
                if let image = try await ImageSearchService.shared.searchDishImage(
                    dishName: retryDish.name,
                    restaurantName: nil // Could be passed from parent view
                ) {
                    // Success - update with new image
                    await MainActor.run {
                        updatedDish.image = image
                        updatedDish.imageLoadError = false
                        updatedDish.isImageLoading = false
                        isRetryingImage = false
                        
                        // Notify parent if callback provided
                        onRetryImage?(updatedDish)
                    }
                } else {
                    // No image found
                    await MainActor.run {
                        updatedDish.imageLoadError = true
                        updatedDish.isImageLoading = false
                        isRetryingImage = false
                    }
                }
            } catch {
                // Error occurred
                await MainActor.run {
                    updatedDish.imageLoadError = true
                    updatedDish.isImageLoading = false
                    isRetryingImage = false
                }
            }
        }
    }
    

}



#Preview {
    VStack(spacing: 20) {
        // For preview, use a generic/empty Dish. Real data comes from extraction.
        DishCardView(dish: Dish(name: "", section: nil, price: nil))
    }
    .padding()
} 