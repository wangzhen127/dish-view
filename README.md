# Dish View iOS App

A modern iOS application that helps customers visualize dishes listed on a restaurant's menu by extracting dish names from photos of text menus and showing representative dish images.

## Features

### 🍽️ Menu Image Input
- Take photos directly in the app using the camera
- Upload existing photos from the device gallery
- Preview and delete functionality for uploaded images
- Support for multiple menu photos

### 🏪 Restaurant Name Extraction
- Automatic extraction of restaurant names from menu photos using OCR
- Manual correction and editing capabilities
- Integration with device location for improved accuracy

### 📝 Dish List Extraction
- OCR-powered text extraction from menu images
- Intelligent parsing of dish names, prices, and sections
- User-friendly interface for reviewing and editing extracted dishes
- Group dishes by menu sections (Appetizers, Main Course, Desserts, etc.)

### 🖼️ Dish Image Retrieval
- Search for representative images for each dish
- Integration with Google Custom Search API
- Local caching of search results
- Fallback handling for missing images
- Retry functionality for failed image searches

### 🎨 Beautiful Dish Display
- Modern grid layout for dish visualization
- Search and filter functionality
- Detailed dish information view
- Responsive design for all iOS devices

### 🔄 Restart Workflow
- Complete app reset functionality
- Clear all stored data and return to initial state

## Architecture

The app follows a clean, modular architecture with the following structure:

```
DishView/
├── App/
│   ├── DishViewApp.swift          # App entry point
│   └── ContentView.swift          # Main workflow orchestrator
│
├── Models/
│   ├── AppState.swift             # Main app state management
│   ├── DishModel.swift            # Dish data model
│   └── RestaurantModel.swift      # Restaurant data model
│
├── Features/
│   ├── MenuInput/
│   │   ├── MenuCaptureView.swift  # Photo capture interface
│   │   └── CameraView.swift       # Camera integration
│   │
│   ├── RestaurantInfo/
│   │   └── RestaurantConfirmationView.swift
│   │
│   ├── DishExtraction/
│   │   ├── DishExtractionView.swift
│   │   └── OCRProcessor.swift     # Text extraction service
│   │
│   ├── DishImageSearch/
│   │   └── ImageSearchService.swift
│   │
│   └── DishDisplay/
│       ├── DishGridView.swift     # Main dish display
│       └── DishCardView.swift     # Individual dish cards
│
├── Shared/
│   ├── Views/
│   │   ├── PrimaryButton.swift    # Reusable button component
│   │   ├── LoadingIndicator.swift # Loading states
│   │   └── EmptyStateView.swift   # Empty state handling
│   └── Extensions/
│       └── UIImage+Resize.swift   # Image utilities
│
└── Resources/
    └── Assets.xcassets           # App icons and assets
```

## Technology Stack

- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Platform**: iOS 17.0+
- **OCR**: Apple Vision Framework
- **Image Search**: Google Custom Search API
- **Architecture**: MVVM with ObservableObject

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Camera and Photo Library permissions

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/dish-view.git
cd dish-view
```

2. Open the project in Xcode:
```bash
open DishView.xcodeproj
```

3. Build and run the project on a simulator or device.

## Usage

### Basic Workflow

1. **Capture Menu**: Take photos or upload existing images of the restaurant menu
2. **Confirm Restaurant**: Review and edit the extracted restaurant name
3. **Extract Dishes**: Review and edit the extracted dish list
4. **View Dishes**: Browse the visualized dishes with images

### Advanced Features

- **Search**: Use the search bar to find specific dishes
- **Filter**: Filter dishes by menu sections
- **Edit**: Tap on dishes to edit their information
- **Restart**: Use "Start Over" to begin a new workflow

## Configuration

### Google Custom Search API

To enable dish image search functionality:

1. Create a Google Cloud Project
2. Enable the Custom Search API
3. Create a Custom Search Engine
4. Add your API credentials to the app

```swift
// In ImageSearchService.swift
let apiKey = "YOUR_API_KEY"
let searchEngineId = "YOUR_SEARCH_ENGINE_ID"
```

## Development

### Adding New Features

1. Create feature-specific views in the appropriate `Features/` directory
2. Update the `AppState` model if new state management is needed
3. Add navigation logic in `ContentView.swift`
4. Update the README with new feature documentation

### Testing

The app includes unit tests and UI tests:

```bash
# Run unit tests
xcodebuild test -scheme DishView -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -scheme DishView -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:DishViewUITests
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple Vision Framework for OCR capabilities
- SwiftUI for the modern UI framework
- Google Custom Search API for image search

## Support

For support, email support@dishview.app or create an issue in this repository.

---

**Note**: This is a production-ready version with all core features implemented. The app is ready for App Store submission. 