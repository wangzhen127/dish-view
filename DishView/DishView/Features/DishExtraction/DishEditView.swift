import SwiftUI

struct DishEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var section: String
    @State private var price: String
    @State private var description: String
    
    let dish: Dish
    let onSave: (Dish) -> Void
    
    init(dish: Dish, onSave: @escaping (Dish) -> Void) {
        self.dish = dish
        self.onSave = onSave
        self._name = State(initialValue: dish.name)
        self._section = State(initialValue: dish.section ?? "")
        self._price = State(initialValue: dish.price ?? "")
        self._description = State(initialValue: dish.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Dish Information") {
                    TextField("Dish Name", text: $name)
                    
                    TextField("Section (e.g., Appetizers, Main Course)", text: $section)
                    
                    TextField("Price (e.g., $12.99)", text: $price)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
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
                        let updatedDish = Dish(
                            name: name,
                            section: section.isEmpty ? nil : section,
                            price: price.isEmpty ? nil : price,
                            description: description.isEmpty ? nil : description
                        )
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
    DishEditView(dish: Dish(name: "Sample Dish", section: "Main Course", price: "$15.99", description: "A delicious sample dish")) { _ in }
} 