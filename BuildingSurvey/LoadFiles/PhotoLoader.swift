//
//  PhotoLoader.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 02.02.2025.
//

import SwiftUI
import PhotosUI

struct PhotoLoader: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoLoader

        init(_ parent: PhotoLoader) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.selectedImage = uiImage
                        }
                    }
                }
            }
        }
    }
}

extension PhotoLoader {
    func saveImageToDocuments(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return }
        
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileName = "gallery_photo_\(UUID().uuidString).jpg"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)

            do {
                try data.write(to: fileURL)
            } catch {
                print("Ошибка при сохранении изображения: \(error)")
            }
        }
    }
}
