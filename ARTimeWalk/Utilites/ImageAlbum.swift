//
//  ImageAlbum.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2022/12/30.
//

import PhotosUI
import SwiftUI

struct ImageAlbum: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> PHPickerCoordinator {
        PHPickerCoordinator(self)
    }
}

class PHPickerCoordinator: NSObject, PHPickerViewControllerDelegate {
    let parent: ImageAlbum
    
    init(_ parent: ImageAlbum) {
        self.parent = parent
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else { return }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let loadImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.image = self.resizeImage(image: loadImage)
                    }
                }
            }
        }
    }
    
    // Resize image while maintaining aspect ratio, up to max size of 2000 pixels
    func resizeImage(image: UIImage) -> UIImage? {
        let maxDimension: CGFloat = 2000.0
        
        var newImage: UIImage?
        
        let width = image.size.width
        let height = image.size.height
        
        var newSize: CGSize
        
        if width > height {
            let ratio = maxDimension / width
            newSize = CGSize(width: maxDimension, height: height * ratio)
        } else {
            let ratio = maxDimension / height
            newSize = CGSize(width: width * ratio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
