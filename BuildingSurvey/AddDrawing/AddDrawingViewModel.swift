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
    private let sendRepository: SendRepository
    
    init(generalRepository: GeneralRepository, sendRepository: SendRepository) {
            self.repository = generalRepository
            self.sendRepository = sendRepository
        }

    func saveDrawing(for project: Project, completion: @escaping () -> Void) {
        print("🚀 [AddDrawingViewModel.saveDrawing] name='\(drawingName)', selectedPDF='\(String(describing: selectedPDF))'")
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
            let pdfData = try Data(contentsOf: destinationURL)
            repository.addDrawing(
                for: project,
                name: newFileName,
                filePath: destinationURL.path,
                pdfData: pdfData,
                servId: nil,
                scale: nil
            )
            print("✅ Локально сохранено: \(newFileName)")
            
            let fileNameSnapshot = newFileName
            let fileURLSnapshot  = destinationURL
            let pdfDataSnapshot  = pdfData
            let projectServIdOpt  = project.servId
            
            Task {
                let drawing = Drawing(
                    id: UUID(),           // или лучше взять тот же UUID, что создал CoreData
                    name: fileNameSnapshot,
                    filePath: fileURLSnapshot.path,
                    pdfData: pdfDataSnapshot,
                    scale: nil,
                    planServId: nil,
                    projectServId: project.servId.map { Int64($0) }
                )
                let result = await sendRepository.addDrawingOnServer(
                    drawing: drawing,
                    project: project,
                    fileURL: fileURLSnapshot
                )
                print("⬅️ [AddDrawingViewModel] Результат отправки на сервер: \(result)")
            }
            
            print("Сохраняем чертеж с именем: \(newFileName) в \(destinationURL.path)")
            
            
            DispatchQueue.main.async {
                completion()
            }
        }
            catch {
            print("Ошибка сохранения файла: \(error.localizedDescription)")
        }
    }

}

