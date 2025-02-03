//
//  ProjectListViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI
import Combine

// Модель состояния для управления состоянием проекта
struct ProjectListUiState {
    var projects: [Project] = []
}

// ViewModel для списка проектов
class ProjectListViewModel: ObservableObject {
    @Published var uiState = ProjectListUiState()
    
    // Делаем свойство repository доступным снаружи
    var repository: GeneralRepository
    
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: GeneralRepository) {
        self.repository = repository
        
        // Подписываемся на изменения в списке проектов и обновляем состояние
        repository.projectsListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] projects in
                self?.uiState.projects = projects
            }
            .store(in: &cancellables)
    }
    
    // Метод для добавления проекта
    func addProject(name: String, isDeleted: Int) {
        repository.addProject(name: name, isDeleted: isDeleted)
    }
    
    func deleteProject(id: UUID) {
            repository.updateProject(id: id, isDeleted: 1)
        }
}

