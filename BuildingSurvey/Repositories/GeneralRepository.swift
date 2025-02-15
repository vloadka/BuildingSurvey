//
//  GeneralRepository.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 15.10.2024.
//

import Foundation
import Combine
import CoreData

class GeneralRepository: ObservableObject {
    @Published private var _projectsList: [Project] = []
    @Published var drawings: [Drawing] = []
    private let context = CoreDataManager.shared.context
    private let fileManager = FileManager.default

    var projectsListPublisher: Published<[Project]>.Publisher {
        return $_projectsList
    }

    init() {
        loadProjects()
    }

    func addProject(name: String, projectFilePath: String? = nil) {
        let newProject = ProjectEntity(context: context)
        newProject.id = UUID()
        newProject.name = name
        newProject.projectFilePath = projectFilePath

        saveContext()
        loadProjects() // Перезагружаем данные
    }

    func deleteProject(id: UUID) {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let project = try context.fetch(fetchRequest).first {
                context.delete(project)
                saveContext()
                loadProjects()
            }
        } catch {
            print("Ошибка удаления проекта: \(error)")
        }
    }
        func loadProjects() {
            let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            do {
                let fetchedProjects = try context.fetch(fetchRequest)
                _projectsList = fetchedProjects.map { projectEntity in
                    Project(
                        id: projectEntity.id ?? UUID(),
                        name: projectEntity.name ?? "Без названия",
                        projectFilePath: projectEntity.projectFilePath
                    )
                }
            } catch {
                print("Ошибка загрузки проектов: \(error)")
            }
        }

    func addDrawing(for project: Project, name: String, filePath: String?) {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)

        do {
            if let projectEntity = try context.fetch(fetchRequest).first {
                let newDrawing = DrawingEntity(context: context)
                newDrawing.id = UUID()
                newDrawing.name = name
                newDrawing.filePath = filePath
                newDrawing.project = projectEntity

                context.insert(newDrawing)
                saveContext()
                
                print("Добавлен чертеж \(name) для проекта \(project.id)") // Лог проверки
            } else {
                print("Ошибка: проект не найден")
            }
        } catch {
            print("Ошибка добавления чертежа: \(error)")
        }
    }

    func deleteDrawing(id: UUID) {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let drawing = try context.fetch(fetchRequest).first {
                context.delete(drawing)
                saveContext()
            }
        } catch {
            print("Ошибка удаления чертежа: \(error)")
        }
    }
    
    func loadDrawings(for project: Project) -> [Drawing] {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project.id == %@", project.id as CVarArg)

        do {
            let drawingEntities = try context.fetch(fetchRequest)
            let drawings = drawingEntities.map { drawingEntity in
                Drawing(
                    id: drawingEntity.id ?? UUID(),
                    name: drawingEntity.name ?? "Без названия",
                    filePath: drawingEntity.filePath
                )
            }
            self.drawings = drawings // Обновляем список чертежей
            return drawings
        } catch {
            print("Ошибка загрузки чертежей: \(error)")
            return []
        }
    }

    private func saveContext() {
        CoreDataManager.shared.saveContext()
    }
}
