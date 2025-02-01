//
//  GeneralRepository.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 15.10.2024.
//

import Foundation
import Combine

// Класс репозитория для управления данными проектов
class GeneralRepository: ObservableObject {
    // Список проектов будет наблюдаемым для обновлений
    @Published private var _projectsList: [Project] = [] // хранит все проекты
    
    // Публичный доступ к списку проектов
    var projectsListPublisher: Published<[Project]>.Publisher {
        return $_projectsList
    }
    
    // Метод для добавления проекта
    func addProject(name: String, isDeleted: Int) {
        let newProject = Project(name: name, isDeleted: isDeleted) // Добавляем isDeleted
        _projectsList.append(newProject)
    }
    
    // Метод для получения всех имен проектов
    func getProjectNames() -> [String] {
        return _projectsList.map { $0.name }
    }
    
    // Метод для получения всех активных проектов (не удаленных)
    func getActiveProjects() -> [Project] {
        return _projectsList.filter { $0.isDeleted == 0 }
    }
    
    // Метод для обновления статуса проекта
    func updateProject(id: UUID, isDeleted: Int) {
        if let index = _projectsList.firstIndex(where: { $0.id == id }) {
            _projectsList[index].isDeleted = isDeleted
        }
    }

}


