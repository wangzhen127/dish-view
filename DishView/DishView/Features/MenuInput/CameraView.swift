import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onError: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            onError("Camera is not available on this device")
            return picker
        }
        
        // Check camera permission status
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            // Add a small delay to ensure camera session is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                picker.sourceType = .camera
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Add a small delay to ensure camera session is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            picker.sourceType = .camera
                        }
                    } else {
                        onError("Camera access denied")
                    }
                }
            }
        case .denied, .restricted:
            onError("Camera access denied. Please enable camera access in Settings.")
            return picker
        @unknown default:
            onError("Unknown camera permission status")
            return picker
        }
        
        picker.allowsEditing = true
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.cameraFlashMode = .auto
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            } else {
                parent.onError("Failed to capture image")
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFailWithError error: Error) {
            let errorMessage: String
            
            if let nsError = error as NSError? {
                switch nsError.code {
                case -12782:
                    errorMessage = "Camera is currently in use by another app. Please close other camera apps and try again."
                case -11800:
                    errorMessage = "Camera session error. Please try again."
                case -11852:
                    errorMessage = "Camera hardware error. Please restart the app."
                default:
                    errorMessage = "Camera error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Camera error: \(error.localizedDescription)"
            }
            
            parent.onError(errorMessage)
            picker.dismiss(animated: true)
        }
    }
} 