//
//  AddDrawingViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 09.02.2025.
//

import SwiftUI

class AddDrawingViewModel: ObservableObject {
    @Published var drawingName: String = ""
    @Published var selectedPDF: URL?
    @Published var showError: Bool = false
    @Published var isDocumentPickerPresented: Bool = false
    
    private let repository: GeneralRepository
    
    init(repository: GeneralRepository) {
        self.repository = repository
    }

    func saveDrawing(for project: Project, completion: @escaping () -> Void) {
        guard !drawingName.isEmpty else {
            showError = true
            print("Имя чертежа не может быть пустым.")
            return
        }

        guard let selectedPDF = selectedPDF else {
            print("Нет выбранного PDF.")
            return
        }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let projectFolder = documentsDirectory.appendingPathComponent("Projects").appendingPathComponent(project.id.uuidString)

        // Создаем уникальное имя для файла, если файл с таким именем уже существует
        var newFileName = "\(drawingName).pdf"
        var destinationURL = projectFolder.appendingPathComponent(newFileName)
        var fileIndex = 1

        while FileManager.default.fileExists(atPath: destinationURL.path) {
            newFileName = "\(drawingName)_\(fileIndex).pdf"
            destinationURL = projectFolder.appendingPathComponent(newFileName)
            fileIndex += 1
        }

        do {
            // Проверка существования папки проекта
            if !FileManager.default.fileExists(atPath: projectFolder.path) {
                try FileManager.default.createDirectory(at: projectFolder, withIntermediateDirectories: true)
            }

            // Копирование PDF в новое место
            try FileManager.default.copyItem(at: selectedPDF, to: destinationURL)

            // Добавление чертеж в репозиторий
            repository.addDrawing(for: project, name: newFileName, filePath: destinationURL.path)
            print("Сохраняем чертеж с именем: \(newFileName) в \(destinationURL.path)")


            DispatchQueue.main.async {
                completion()
            }
        } catch {
            print("Ошибка сохранения файла: \(error.localizedDescription)")
        }
    }

}

