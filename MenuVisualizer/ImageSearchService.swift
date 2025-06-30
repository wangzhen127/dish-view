// ImageSearchService.swift
// MenuVisualizer
//
// Created by Jules on $(date +%F).
//

import SwiftUI // For UIImage, though network requests might not strictly need it.

class ImageSearchService {
    // Placeholder for your actual API key and search engine ID
    let apiKey = "YOUR_API_KEY"
    let searchEngineId = "YOUR_SEARCH_ENGINE_ID"

    func searchImage(for dishName: String, completion: @escaping (UIImage?) -> Void) {
        // Construct the search URL
        // This is a generic example, you'll need to adapt it to your chosen search API
        guard let encodedDishName = dishName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/customsearch/v1?key=\(apiKey)&cx=\(searchEngineId)&q=\(encodedDishName)&searchType=image&num=1") else {
            print("Error: Invalid URL for \(dishName)")
            completion(nil)
            return
        }

        // Perform the network request
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error searching for image for \(dishName): \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("Error: No data received for \(dishName)")
                completion(nil)
                return
            }

            // Parse the JSON response (this will vary based on the API)
            // For Google Custom Search, you'd look for `items[0].link` or similar
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let firstItem = items.first,
                   let imageUrlString = firstItem["link"] as? String,
                   let imageUrl = URL(string: imageUrlString) {

                    // Download the image
                    self.downloadImage(from: imageUrl, completion: completion)
                } else {
                    print("Error: Could not parse JSON or find image URL for \(dishName)")
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON for \(dishName): \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading image from \(url): \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                print("Error: No data or invalid image data from \(url)")
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
