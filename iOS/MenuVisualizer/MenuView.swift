// MenuView.swift
// MenuVisualizer
//
// Created by Jules on $(date +%F).
//

import SwiftUI

import SwiftUI

struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let image: UIImage? // Now holds the actual UIImage
}

struct MenuView: View {
    let menuItems: [MenuItem]

    var body: some View {
        List(menuItems) { item in
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    if let uiImage = item.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100) // Adjusted frame for better display
                            .cornerRadius(8)
                    } else {
                        Text("Image not found")
                            .font(.caption)
                            .frame(width: 100, height: 100) // Keep consistent frame size
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                Spacer() // Pushes content to the left
            }
        }
        .navigationTitle("Menu")
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        // Example data for preview
        MenuView(menuItems: [
            MenuItem(name: "Preview Dish 1", image: UIImage(systemName: "photo.fill")),
            MenuItem(name: "Preview Dish 2 (No Image)", image: nil),
            MenuItem(name: "Preview Dish 3", image: UIImage(systemName: "photo.fill"))
        ])
    }
}
