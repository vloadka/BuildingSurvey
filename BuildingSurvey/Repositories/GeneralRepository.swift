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
    private let fileManager = FileManager.default
    private let outputDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! // Путь к папке документов
    
    // Публичный доступ к списку проектов
    var projectsListPublisher: Published<[Project]>.Publisher {
        return $_projectsList
    }
    
    // Метод для добавления проекта
//    func addProject(name: String, isDeleted: Int) {
//        let newProject = Project(name: name, isDeleted: isDeleted) // Добавляем isDeleted
//        _projectsList.append(newProject)
//    }
   
    func addProject(name: String, isDeleted: Int, projectFilePath: String? = nil) {
        let fileName = "\(name)_\(UUID().uuidString)" // Уникальное имя файла
        let directoryURL = outputDir.appendingPathComponent(fileName) // Путь к каталогу проекта

        // Создание директории, если она не существует
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Ошибка при создании директории: \(error)")
            }
        }

        var finalFilePath = "" // По умолчанию путь к файлу пустой

        // Если передан путь к файлу, создаем его копию в каталоге проекта
        if let projectFilePath = projectFilePath {
            let fileURL = URL(fileURLWithPath: projectFilePath)
            let fileExtension = fileURL.pathExtension // Получаем расширение файла
            let newFileName = "\(fileName).\(fileExtension)" // Новое имя файла
            let destinationURL = directoryURL.appendingPathComponent(newFileName) // Полный путь к файлу

            do {
                try fileManager.copyItem(at: fileURL, to: destinationURL) // Копируем файл
                finalFilePath = destinationURL.path // Обновляем путь
            } catch {
                print("Ошибка при копировании файла: \(error)")
            }
        }

        let newProject = Project(name: name, isDeleted: isDeleted, projectFilePath: finalFilePath) // Создаем проект
        _projectsList.append(newProject) // Добавляем в список
    }
    
    // Метод для получения всех имен проектов
    func getProjectNames() -> [String] {
        return _projectsList.map { $0.name }
    }
    
    // Метод для получения всех активных проектов (не удаленных)
    func getActiveProjects() -> [Project] {
        return _projectsList.filter { $0.isDeleted == 0 }
    }
    
    // Метод для обновления статуса проекта(по факту удаление(по факту скрытие))
    func updateProject(id: UUID, isDeleted: Int) {
        if let index = _projectsList.firstIndex(where: { $0.id == id }) {
            _projectsList[index].isDeleted = isDeleted
        }
    }
}
