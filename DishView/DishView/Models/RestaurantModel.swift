import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable {
    let id = UUID()
    var name: String
    var address: String?
    var coordinates: CLLocationCoordinate2D?
    var phoneNumber: String?
    var website: String?
    var cuisine: String?
    
    init(name: String, address: String? = nil, coordinates: CLLocationCoordinate2D? = nil) {
        self.name = name
        self.address = address
        self.coordinates = coordinates
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, phoneNumber, website, cuisine
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        
        if let latitude = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(cuisine, forKey: .cuisine)
        
        if let coordinates = coordinates {
            try container.encode(coordinates.latitude, forKey: .latitude)
            try container.encode(coordinates.longitude, forKey: .longitude)
        }
    }
} 