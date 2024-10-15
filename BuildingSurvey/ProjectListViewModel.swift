//
//  ProjectListViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI
import Combine

class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    
    // Делаем свойство repository доступным снаружи
    var repository: ProjectRepository
    
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: ProjectRepository) {
        self.repository = repository
        // Подписываемся на изменения в списке проектов
        repository.projectsListPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$projects)
    }
}
