//
//  TakePhoto.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 02.02.2025.
//

import SwiftUI
import AVFoundation

struct TakePhoto: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedPhotoPath: String?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: TakePhoto

        init(_ parent: TakePhoto) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                
                // Сохраняем изображение в Documents
                if let data = image.jpegData(compressionQuality: 1.0) {
                    let fileName = "captured_photo.jpg"
                    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentDirectory.appendingPathComponent(fileName)

                    do {
                        try data.write(to: fileURL)
                        parent.selectedPhotoPath = fileURL.path // Устанавливаем полный путь
                    } catch {
                        print("Ошибка при сохранении изображения: \(error)")
                    }
                }
            }
                picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

