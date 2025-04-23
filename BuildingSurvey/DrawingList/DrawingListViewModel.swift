//
//  DrawingListViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 09.02.2025.
//

import SwiftUI
import Combine

class DrawingListViewModel: ObservableObject {
    @Published var drawings: [Drawing] = []
    @Published var isScaleValid: Bool = true

    let repository: GeneralRepository
    let sendRepository: SendRepository
    private let project: Project

    init(repository: GeneralRepository, project: Project, sendRepository: SendRepository ) {
        self.repository = repository
        self.project = project
        self.sendRepository = sendRepository
        loadDrawings()

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DrawingAdded"),
            object: nil,
            queue: .main
        ) { _ in
            self.loadDrawings()
        }
    }

    func loadDrawings() {
        drawings = repository.loadDrawings(for: project)
    }
    
    @MainActor
    func fetchDrawingsFromServer() async {
        // 1) Попытка получить чертежи с сервера
        let result = await sendRepository.getDrawingsFromServer(project: project)
        switch result {
        case .success:
            // 2) Если успешно, перезагружаем из локального репозитория
            loadDrawings()
        default:
            // 3) Можно обработать ошибку (показать alert, лог и т.п.)
            print("Ошибка загрузки чертежей с сервера: \(result)")
        }
    }
    
    @MainActor
    func prepareDrawingFile(_ drawing: Drawing) async throws -> URL {
        // 1) Попытка открыть локальный файл
        if let path = drawing.filePath,
           FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        // 2) Иначе – скачиваем с сервера
        let result = await sendRepository.downloadDrawingFile(project: project, drawing: drawing)
        guard result == .success,
              let newPath = repository.loadDrawings(for: project)
                                  .first(where: { $0.id == drawing.id })?
                                  .filePath
        else {
            throw NSError(domain: "DownloadError", code: 1, userInfo: nil)
        }
        return URL(fileURLWithPath: newPath)
    }

    func deleteDrawing(_ drawing: Drawing) {
        Task {
            // 1) вызываем удаление на сервере
            let result = await sendRepository.deleteDrawingOnServer(drawing: drawing)
            
            // 2) возвращаемся на UI-поток
            await MainActor.run {
                switch result {
                case .success:
                    // 3a) если всё ок — удаляем локально и обновляем список
                    repository.deleteDrawing(id: drawing.id)
                    loadDrawings()
                default:
                    // 3b) в случае ошибки — можно прокинуть флаг @Published и показать Alert
                    print("Ошибка удаления чертежа на сервере: \(result)")
                    // Например:
                    // self.showDeleteError = true
                }
            }
        }
    }

    func validateScale(_ text: String) -> Bool {
        let parts = text.split(separator: ":").map(String.init)
        guard parts.count == 2,
              let a = Double(parts[0]), a > 0,
              let b = Double(parts[1]), b > 0
        else {
            return false
        }
        return true
    }

    func saveScale(_ text: String, for drawing: Drawing) -> Bool {
        guard validateScale(text) else {
            isScaleValid = false
            return false
        }

        let parts = text.split(separator: ":").map(String.init)
        let a = Double(parts[0])!
        let b = Double(parts[1])!
        let resultScale = a / b

        repository.updateDrawingScale(drawingId: drawing.id, scale: resultScale)

        loadDrawings()

        isScaleValid = true
        return true
    }
}
