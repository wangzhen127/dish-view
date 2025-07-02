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
    let dish: Dish
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Dish Image
                    if let image = dish.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
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
                            Text(dish.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            if let section = dish.section {
                                Text(section)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let price = dish.price {
                            Text(price)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        if let description = dish.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                // TODO: Implement retry image search
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
                            
                            Button(action: {
                                // TODO: Implement share functionality
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Dish")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                                .foregroundColor(.green)
                            }
                        }
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
}

#Preview {
    VStack(spacing: 20) {
        DishCardView(dish: Dish(name: "Margherita Pizza", section: "Main Course", price: "$18"))
        
        DishCardView(dish: Dish(name: "Caesar Salad", section: "Appetizers", price: "$12"))
    }
    .padding()
} 