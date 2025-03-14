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
    @Binding var showError: Bool // Флаг для управления ошибкой
    
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
                DispatchQueue.main.async {
                    self.parent.showError = true
                }
                return
            }
            defer { selectedFileURL.stopAccessingSecurityScopedResource() }
            
            // Загрузка изображения
            if let image = UIImage(contentsOfFile: selectedFileURL.path) {
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.showError = true
                }
            }
        }
    }
}
