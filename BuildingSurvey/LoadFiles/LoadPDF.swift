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
                let projectFolder = self.getProjectFolder()
                
                if !fileManager.fileExists(atPath: projectFolder.path) {
                    try fileManager.createDirectory(at: projectFolder, withIntermediateDirectories: true)
                }

                let destinationURL = projectFolder.appendingPathComponent("single_page.pdf")

                // Создание одностраничного PDF
                if let document = PDFDocument(url: selectedFileURL),
                   let firstPage = document.page(at: 0) {

                    let newDocument = PDFDocument()
                    newDocument.insert(firstPage, at: 0)

                    if newDocument.write(to: destinationURL) {
                        print("Сохранён одностраничный PDF: \(destinationURL.path)")
                        
                        DispatchQueue.main.async {
                            self.parent.selectedPDF = destinationURL
                            self.parent.fileName = "single_page.pdf"
                        }
                    } else {
                        print("Ошибка сохранения одностраничного PDF")
                        DispatchQueue.main.async {
                            self.parent.showError = true
                        }
                    }
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
