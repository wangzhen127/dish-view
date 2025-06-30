// ImageSearchServiceProtocol.swift
// MenuVisualizer
//
// Created by Jules on $(date +%F).
//

import SwiftUI // For UIImage

protocol ImageSearchServiceProtocol {
    func searchImage(for dishName: String, completion: @escaping (UIImage?) -> Void)
}

// Make existing ImageSearchService conform to this protocol
extension ImageSearchService: ImageSearchServiceProtocol {}
