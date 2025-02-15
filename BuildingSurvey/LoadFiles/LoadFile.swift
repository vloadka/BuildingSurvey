//
//  LoadFile.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 02.02.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct LoadFile: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedPhotoPath: String?
    @Binding var showError: Bool // Свойство для управления ошибкой
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image])
        documentPicker.delegate = context.coordinator
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: LoadFile
        
        init(_ parent: LoadFile) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedFileURL = urls.first else { return }

            // Запрос доступа к файлу
            guard selectedFileURL.startAccessingSecurityScopedResource() else {
                print("Не удалось получить доступ к файлу по URL: \(selectedFileURL)")
                DispatchQueue.main.async {
                    self.parent.showError = true // Установите флаг ошибки
                }
                return
            }

            defer { selectedFileURL.stopAccessingSecurityScopedResource() }

            // Загрузка изображения
            if let image = UIImage(contentsOfFile: selectedFileURL.path) {
                // Создание уникального имени файла
                let uniqueFileName = "image_\(UUID().uuidString).jpg"

                // Сохранение изображения в папку документов
                if let savedImageURL = saveImageToDocumentsDirectory(image: image, fileName: uniqueFileName) {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                        self.parent.selectedPhotoPath = savedImageURL.path
                        print("Изображение сохранено и интерфейс обновлен")
                    }
                }
            } else {
                print("Не удалось загрузить изображение по URL: \(selectedFileURL)")
                DispatchQueue.main.async {
                    self.parent.showError = true //  флаг ошибки
                }
            }
        }

        // Функция для сохранения изображения в папку документов
        func saveImageToDocumentsDirectory(image: UIImage, fileName: String) -> URL? {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent(fileName)
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: fileURL)
                return fileURL
            }
            return nil
        }
    }
}
