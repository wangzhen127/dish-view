//
//  ContentView.swift
//  DishView
//
//  Created by Zhen Wang on 7/2/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            switch appState.currentStep {
            case .menuInput:
                MenuCaptureView(appState: appState)
            case .menuExtraction:
                MenuExtractionView(appState: appState)
            case .dishDisplay:
                DishGridView(appState: appState)
            }
        }
        .overlay(
            Group {
                if appState.isLoading {
                    LoadingIndicator()
                }
            }
        )
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
