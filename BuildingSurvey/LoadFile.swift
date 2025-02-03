//
//  LoadFile.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 02.02.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import Photos

struct LoadFile: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedPhotoPath: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: LoadFile

        init(_ parent: LoadFile) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Получаем данные изображения
            do {
                let data = try Data(contentsOf: url)
                if let image = UIImage(data: data) {
                    print("Выбранный файл: \(url.path)")
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                        self.parent.selectedPhotoPath = url.path // Сохраняем путь к файлу
                    }
                }
            } catch {
                print("Ошибка при загрузке изображения: \(error)")
            }
        }
    }
}
