// MainView.swift
// MenuVisualizer
//
// Created by Jules on $(date +%F).
//

import SwiftUI
import Vision

struct MainView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isMenu = false
    // Make menuItems public for accessibility from tests, or internal if tests are in the same module
    @State var menuItems: [MenuItem] = [] // To store parsed menu items
    private let imageSearchService: ImageSearchServiceProtocol // Instance of the search service

    // Initializer for dependency injection, useful for testing
    init(imageSearchService: ImageSearchServiceProtocol = ImageSearchService()) {
        self.imageSearchService = imageSearchService
    }

    var body: some View {
        NavigationView {
            VStack {
                if selectedImage != nil {
                    Image(uiImage: selectedImage!)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                } else {
                    Text("No image selected")
                        .frame(height: 300)
                }

                Button("Select Image") {
                    showingImagePicker = true
                }
                .padding()

                if selectedImage != nil {
                    if isMenu {
                        // Navigate to MenuView when menu is detected and parsed
                        NavigationLink("View Menu", destination: MenuView(menuItems: menuItems))
                            .padding()
                    } else {
                        Text("This is not a menu.")
                    }
                }
            }
            .navigationTitle("Menu Visualizer")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    func loadImage() {
        guard let selectedImage = selectedImage else { return }
        detectAndParseMenu(image: selectedImage)
    }

    func detectAndParseMenu(image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Text recognition error: \(error?.localizedDescription ?? "Unknown error")")
                self.isMenu = false
                return
            }

            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

            // Basic menu detection (can be improved)
            if text.count > 50 { // Adjusted threshold
                self.isMenu = true
                self.parseMenuText(text)
            } else {
                self.isMenu = false
                self.menuItems = [] // Clear previous items if not a menu
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision request: \(error)")
            self.isMenu = false
            self.menuItems = []
        }
    }

    func parseMenuText(_ text: String) {
        // Simple parsing logic: assume each line is a dish.
        let lines = text.split(whereSeparator: \.isNewline)
        var items: [MenuItem] = []
        let group = DispatchGroup()

        for line in lines {
            let dishName = String(line)
            group.enter()
            imageSearchService.searchImage(for: dishName) { image in
                // Create MenuItem with the actual image or nil if not found
                items.append(MenuItem(name: dishName, image: image))
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.menuItems = items
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
