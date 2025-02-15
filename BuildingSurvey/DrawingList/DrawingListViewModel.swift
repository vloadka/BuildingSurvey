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
    let repository: GeneralRepository
    private var project: Project

    init(repository: GeneralRepository, project: Project) {
        self.repository = repository
        self.project = project
        loadDrawings()

        NotificationCenter.default.addObserver(forName: NSNotification.Name("DrawingAdded"), object: nil, queue: .main) { _ in
            self.loadDrawings()
        }
    }
    
    func loadDrawings() {
            drawings = repository.loadDrawings(for: project)
        }

        func deleteDrawing(drawing: Drawing) {
            repository.deleteDrawing(id: drawing.id)
            loadDrawings()
        }
}
