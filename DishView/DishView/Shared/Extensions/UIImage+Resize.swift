import UIKit

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
    
    func resized(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }
        
        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return resized(to: newSize)
    }
    
    func toJPEGData(compressionQuality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
} 
