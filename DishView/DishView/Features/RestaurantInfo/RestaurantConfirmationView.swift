import SwiftUI

struct RestaurantConfirmationView: View {
    @ObservedObject var appState: AppState
    @State private var restaurantName: String = ""
    @State private var isExtracting: Bool = true
    @State private var extractionError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "building.2")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Restaurant Name")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Confirm or edit the restaurant name extracted from your menu photos")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if isExtracting {
                    Spacer()
                    
                    LoadingIndicator("Extracting restaurant name...")
                    
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
                            extractRestaurantName()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    // Restaurant Name Input
                    VStack(spacing: 16) {
                        Text("Restaurant Name")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("Enter restaurant name", text: $restaurantName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                        
                        if !restaurantName.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Restaurant name confirmed")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        PrimaryButton(
                            "Continue",
                            isDisabled: restaurantName.isEmpty
                        ) {
                            appState.setRestaurantName(restaurantName)
                            appState.currentStep = .menuExtraction
                        }
                        
                        Button("Back") {
                            appState.currentStep = .menuInput
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                extractRestaurantName()
            }
        }
    }
    
    private func extractRestaurantName() {
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
                    
                    if let name = menuData.restaurantName, !name.isEmpty {
                        restaurantName = name
                    } else {
                        restaurantName = ""
                        extractionError = "Could not extract restaurant name from the menu images. Please enter it manually."
                    }
                    isExtracting = false
                }
            } catch {
                await MainActor.run {
                    extractionError = "Failed to extract restaurant name: \(error.localizedDescription)"
                    isExtracting = false
                }
            }
        }
    }
}

#Preview {
    RestaurantConfirmationView(appState: AppState())
} 