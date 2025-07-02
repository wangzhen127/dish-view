import SwiftUI

struct RestaurantConfirmationView: View {
    @ObservedObject var appState: AppState
    @State private var restaurantName: String = ""
    @State private var isExtracting: Bool = true
    
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
                            appState.currentStep = .dishExtraction
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
                // Simulate restaurant name extraction
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    restaurantName = "Sample Restaurant"
                    isExtracting = false
                }
            }
        }
    }
}

#Preview {
    RestaurantConfirmationView(appState: AppState())
} 