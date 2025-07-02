import SwiftUI
import Foundation

struct Dish: Identifiable, Codable {
    let id = UUID()
    var name: String
    var imageURL: String?
    var image: UIImage?
    var section: String?
    var price: String?
    var description: String?
    var isImageLoading: Bool = false
    var imageLoadError: Bool = false
    
    init(name: String, section: String? = nil, price: String? = nil, description: String? = nil) {
        self.name = name
        self.section = section
        self.price = price
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageURL, section, price, description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        section = try container.decodeIfPresent(String.self, forKey: .section)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(section, forKey: .section)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(description, forKey: .description)
    }
} 