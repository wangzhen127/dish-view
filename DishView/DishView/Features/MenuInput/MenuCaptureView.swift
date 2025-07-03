import SwiftUI
import PhotosUI

struct MenuCaptureView: View {
    @ObservedObject var appState: AppState
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var cameraError: String?
    @State private var showingErrorAlert = false
    @State private var retryCount = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Take photos of the restaurant menu to extract dish information")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Image Grid
                if !appState.menuImages.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(Array(appState.menuImages.enumerated()), id: \.offset) { index, image in
                                MenuImageCard(
                                    image: image,
                                    onDelete: {
                                        appState.removeMenuImage(at: index)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                }
                
                // Action Buttons - back to original location
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Take Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .foregroundColor(.blue)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .foregroundColor(.blue)
                        }
                    }
                    
                    PrimaryButton(
                        "Continue",
                        isDisabled: appState.menuImages.isEmpty
                    ) {
                        appState.currentStep = .menuExtraction
                    }
                }
                .padding()
            }
            .navigationTitle("Menu Capture")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            appState.addMenuImage(image)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(
                    onImageCaptured: { image in
                        appState.addMenuImage(image)
                    },
                    onError: { error in
                        cameraError = error
                        showingErrorAlert = true
                    }
                )
            }
            .alert("Camera Error", isPresented: $showingErrorAlert) {
                Button("Retry") {
                    retryCount += 1
                    showingCamera = true
                }
                Button("OK") { }
            } message: {
                Text(cameraError ?? "Unknown error")
            }
        }
    }
}

struct MenuImageCard: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }
}

#Preview {
    MenuCaptureView(appState: AppState())
} 