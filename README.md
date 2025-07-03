# DishView iOS App

A modern iOS application that transforms restaurant menu photos into a visual dining experience. Using AI-powered text extraction and image generation, DishView extracts dish information from menu photos and generates realistic dish images to help customers visualize their dining options.

## 🍽️ Core Functionality

### 1. **Menu Photo Capture**
- Take photos directly in the app using the built-in camera
- Upload existing photos from the device gallery
- Preview and manage multiple menu images
- Delete unwanted photos before processing

### 2. **AI-Powered Menu Analysis**
- **Restaurant Name Extraction**: Automatically identifies and extracts restaurant names from menu images
- **Dish Information Extraction**: Uses Google Gemini AI to intelligently parse dish names, sections, and prices
- **Structured Data Output**: Organizes extracted information into a clean, editable format

### 3. **AI-Generated Dish Images**
- **Realistic Image Generation**: Uses Google Gemini's image generation model to create representative dish images
- **Parallel Processing**: Generates multiple dish images simultaneously with controlled concurrency (3 parallel requests)
- **Progressive Loading**: Images appear as soon as they're ready, providing immediate visual feedback
- **Smart Retry Logic**: Automatic retry with exponential backoff for failed image generation attempts

### 4. **Interactive Dish Display**
- **Grid Layout**: Beautiful, responsive grid display of dishes with generated images
- **Search & Filter**: Search dishes by name and filter by menu sections
- **Dish Management**: Edit dish information, delete dishes, and reorganize the menu
- **Restaurant Context**: Displays restaurant name and dish count for context

## 🏗️ App Architecture

### **Workflow-Based Design**
The app follows a clear 3-step workflow:

1. **Menu Input** (`MenuCaptureView`): Capture and manage menu photos
2. **Menu Extraction** (`MenuExtractionView`): Review and edit extracted restaurant and dish information
3. **Dish Display** (`DishGridView`): Browse dishes with generated images

### **Technical Architecture**
```
DishView/
├── App/
│   ├── DishViewApp.swift          # App entry point
│   └── ContentView.swift          # Main workflow orchestrator
│
├── Models/
│   ├── AppState.swift             # Central state management
│   └── DishModel.swift            # Dish data model
│
├── Features/
│   ├── MenuInput/
│   │   ├── MenuCaptureView.swift  # Photo capture interface
│   │   └── CameraView.swift       # Camera integration
│   │
│   ├── DishExtraction/
│   │   ├── MenuExtractionView.swift # Extraction review interface
│   │   ├── DishEditView.swift     # Dish editing interface
│   │   └── OCRProcessor.swift     # AI-powered text extraction
│   │
│   ├── DishImageGeneration/
│   │   └── ImageGenerationService.swift # AI image generation
│   │
│   └── DishDisplay/
│       ├── DishGridView.swift     # Main dish display
│       └── DishCardView.swift     # Individual dish cards
│
├── Shared/
│   └── Views/
│       ├── PrimaryButton.swift    # Reusable button component
│       ├── LoadingIndicator.swift # Loading states
│       └── EmptyStateView.swift   # Empty state handling
│
└── Assets.xcassets               # App icons and assets
```

## 🛠️ Technology Stack

- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Platform**: iOS 18.5+
- **AI Services**: 
  - **Google Gemini API** for text extraction and image generation
  - **Gemini 2.5 Flash** for menu analysis
  - **Gemini 2.0 Flash Preview** for image generation
- **Architecture**: MVVM with ObservableObject pattern
- **Concurrency**: Swift Concurrency with TaskGroup for parallel processing

## 🚀 Key Features

### **Smart Caching & Performance**
- **Image State Tracking**: Detects when menu images change to avoid redundant processing
- **Progressive Image Loading**: Images appear as they're generated, not all at once
- **Concurrency Control**: Limits parallel API requests to prevent rate limiting

### **Error Handling & Resilience**
- **Exponential Backoff**: Intelligent retry logic for transient API errors
- **Graceful Degradation**: App continues to function even if some images fail to generate
- **User-Friendly Errors**: Clear error messages and recovery options

### **User Experience**
- **Intuitive Workflow**: Clear 3-step process from photo to visualization
- **Real-Time Feedback**: Loading indicators and progress updates throughout
- **Responsive Design**: Optimized for all iOS device sizes
- **Accessibility**: Built with accessibility best practices

## 📱 Requirements

- **iOS**: 18.5 or later
- **Xcode**: 16.0 or later
- **Swift**: 5.9 or later
- **Permissions**: Camera and Photo Library access

## ⚙️ Setup & Configuration

### 1. **Clone the Repository**
```bash
git clone https://github.com/yourusername/dish-view.git
cd dish-view/DishView
```

### 2. **Configure API Keys**
Create a `Config.plist` file in the project root with your Google Gemini API key:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>YOUR_GEMINI_API_KEY_HERE</string>
</dict>
</plist>
```

### 3. **Get Your Gemini API Key**
1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Ensure the key has access to both text and image generation models

### 4. **Build and Run**
```bash
open DishView.xcodeproj
# Build and run on simulator or device
```

## 🎯 Usage Guide

### **Step 1: Capture Menu Photos**
1. Open the app and tap "Take Photo" or "Choose Photo"
2. Capture clear photos of the restaurant menu
3. Add multiple photos if needed for complete menu coverage
4. Tap "Continue" when ready

### **Step 2: Review Extracted Information**
1. Review the automatically extracted restaurant name
2. Check the list of extracted dishes, sections, and prices
3. Edit any incorrect information by tapping on dishes
4. Add or remove dishes as needed
5. Tap "Continue" to proceed

### **Step 3: Browse Visualized Dishes**
1. Wait for AI-generated dish images to appear (generates progressively)
2. Use the search bar to find specific dishes
3. Filter dishes by menu sections using the filter chips
4. Tap "Start Over" to begin with a new menu

## 🔧 Development

### **Adding New Features**
1. Create feature-specific views in the appropriate `Features/` directory
2. Update `AppState.swift` for new state management needs
3. Add navigation logic in `ContentView.swift`
4. Follow the existing MVVM pattern

### **Testing**
```bash
# Build the project
xcodebuild -project DishView.xcodeproj -scheme DishView -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run on simulator
xcodebuild -project DishView.xcodeproj -scheme DishView -destination 'platform=iOS Simulator,name=iPhone 16' run
```

### **Performance Optimization**
- **Concurrency**: Currently set to 3 parallel image generation requests
- **Caching**: Image state tracking prevents redundant processing
- **Memory Management**: Efficient image handling and cleanup

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Gemini API** for AI-powered text extraction and image generation
- **SwiftUI** for the modern, declarative UI framework
- **Apple** for the robust iOS development ecosystem

---

**DishView** - Transforming menu photos into visual dining experiences with AI. 🍽️✨ 