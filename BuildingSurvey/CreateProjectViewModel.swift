//
//  CreateProjectViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

class CreateProjectViewModel: ObservableObject {
    private var repository: ProjectRepository
    
    init(repository: ProjectRepository) {
        self.repository = repository
    }
    
    // Метод для сохранения проекта
    func saveProject(name: String) {
        repository.addProject(name: name)
    }
}
