//
//  LoadPDF.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 09.02.2025.
//
import SwiftUI
import UniformTypeIdentifiers
import UIKit
import PDFKit

struct LoadPDF: UIViewControllerRepresentable {
    @Binding var selectedPDF: URL?
    @Binding var showError: Bool
    @Binding var fileName: String
    let project: Project

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: LoadPDF

        init(_ parent: LoadPDF) {
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

            do {
                let fileManager = FileManager.default
                let projectFolder = getProjectFolder()
                
                if !fileManager.fileExists(atPath: projectFolder.path) {
                    try fileManager.createDirectory(at: projectFolder, withIntermediateDirectories: true)
                }
                
                // Копируем оригинальный PDF в папку проекта с его исходным именем
                let destinationURL = projectFolder.appendingPathComponent(selectedFileURL.lastPathComponent)
                
                // Если файл с таким именем уже существует, удаляем его
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                try fileManager.copyItem(at: selectedFileURL, to: destinationURL)
                
                print("Файл скопирован в: \(destinationURL.path)")
                
                DispatchQueue.main.async {
                    self.parent.selectedPDF = destinationURL
                    self.parent.fileName = selectedFileURL.lastPathComponent
                }
            } catch {
                DispatchQueue.main.async {
                    self.parent.showError = true
                }
                print("Ошибка обработки PDF: \(error.localizedDescription)")
            }
        }

        private func getProjectFolder() -> URL {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsDirectory.appendingPathComponent("Projects").appendingPathComponent(parent.project.id.uuidString)
        }
    }
}

