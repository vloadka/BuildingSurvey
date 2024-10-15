//
//  GeneralRepository.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 15.10.2024.
//

import Foundation
import Combine

class ProjectRepository: ObservableObject {
    // Список проектов будет наблюдаемым для обновлений
    @Published private var _projectsList: [Project] = []
    
    // Публичный доступ к списку проектов
    var projectsListPublisher: Published<[Project]>.Publisher {
        return $_projectsList
    }
    
    // Метод для добавления проекта
    func addProject(name: String) {
        let newProject = Project(name: name)
        _projectsList.append(newProject)
    }
}
