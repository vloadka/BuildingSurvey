//
//  GeneralRepository.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 15.10.2024.
//

import Foundation
import Combine
import CoreData
import UIKit

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

    func addProject(name: String, coverImageData: Data? = nil) {
        let newProject = ProjectEntity(context: context)
        newProject.id = UUID()
        newProject.name = name
        newProject.coverImageData = coverImageData
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
                    coverImageData: projectEntity.coverImageData
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
    
    func saveLine(for drawingId: UUID, start: CGPoint, end: CGPoint) {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)

        do {
            if let drawing = try context.fetch(fetchRequest).first {
                let line = LineEntity(context: context)
                line.id = UUID()
                line.startX = start.x
                line.startY = start.y
                line.endX = end.x
                line.endY = end.y
                line.drawing = drawing  // Связываем линию с чертежом
                
                saveContext()
            }
        } catch {
            print("Ошибка сохранения линии: \(error)")
        }
    }

    func loadLines(for drawingId: UUID) -> [(CGPoint, CGPoint)] {
        let fetchRequest: NSFetchRequest<LineEntity> = LineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)

        do {
            let lines = try context.fetch(fetchRequest)
            return lines.map { line in
                let start = CGPoint(x: line.startX, y: line.startY)
                let end = CGPoint(x: line.endX, y: line.endY)
                return (start, end)
            }
        } catch {
            print("Ошибка загрузки линий: \(error)")
            return []
        }
    }

    private func saveContext() {
        CoreDataManager.shared.saveContext()
    }
    
    func getNextPhotoNumber(forDrawing drawingId: UUID) -> Int {
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        
        do {
            let photos = try context.fetch(fetchRequest)
            // Вычисляем максимальный номер фото и возвращаем следующий номер (если фото отсутствуют, возвращаем 1)
            let maxNumber = photos.map { Int($0.photoNumber) }.max() ?? 0
            return maxNumber + 1
        } catch {
            print("Ошибка получения номера фото: \(error)")
            return 1
        }
    }
    
    func savePhotoMarker(forDrawing drawingId: UUID,
                         withId id: UUID,
                         image: UIImage,
                         photoNumber: Int,
                         timestamp: Date,
                         coordinateX: Double,
                         coordinateY: Double) {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
        
        do {
            if let drawing = try context.fetch(fetchRequest).first {
                let photoEntity = PhotoEntity(context: context)
                photoEntity.id = id  // Используем переданный идентификатор
                photoEntity.imageData = image.jpegData(compressionQuality: 0.8)
                photoEntity.photoNumber = Int64(photoNumber)
                photoEntity.timestamp = timestamp
                photoEntity.coordinateX = coordinateX
                photoEntity.coordinateY = coordinateY
                photoEntity.drawing = drawing
                saveContext()
            } else {
                print("Ошибка: Чертеж с id \(drawingId) не найден.")
            }
        } catch {
            print("Ошибка сохранения фото-маркера: \(error)")
        }
    }

    func loadPhotoMarkers(forDrawing drawingId: UUID) -> [PhotoMarkerData] {
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        do {
            let photoEntities = try context.fetch(fetchRequest)
            return photoEntities.compactMap { photo in
                guard let id = photo.id,
                      let data = photo.imageData,
                      let image = UIImage(data: data) else { return nil }
                let coordinate = CGPoint(x: photo.coordinateX, y: photo.coordinateY)
                return PhotoMarkerData(id: id, image: image, coordinate: coordinate)
            }
        } catch {
            print("Ошибка загрузки фото-маркеров: \(error)")
            return []
        }
    }
    
    func deletePhotoMarker(withId id: UUID) {
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let photoEntity = try context.fetch(fetchRequest).first {
                context.delete(photoEntity)
                saveContext()
            }
        } catch {
            print("Ошибка удаления фото-маркера: \(error)")
        }
    }
    
    func savePoint(forDrawing drawingId: UUID, withId id: UUID = UUID(), coordinate: CGPoint) {
            let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
            do {
                if let drawing = try context.fetch(fetchRequest).first {
                    let pointEntity = PointEntity(context: context)
                    pointEntity.id = id
                    pointEntity.coordinateX = coordinate.x
                    pointEntity.coordinateY = coordinate.y
                    pointEntity.drawing = drawing
                    saveContext()
                } else {
                    print("Ошибка: Чертеж с id \(drawingId) не найден.")
                }
            } catch {
                print("Ошибка сохранения точки: \(error)")
            }
        }

        func loadPoints(forDrawing drawingId: UUID) -> [PointMarkerData] {
            let fetchRequest: NSFetchRequest<PointEntity> = PointEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
            do {
                let pointEntities = try context.fetch(fetchRequest)
                return pointEntities.compactMap { point in
                    guard let id = point.id else { return nil }
                    return PointMarkerData(id: id, coordinate: CGPoint(x: point.coordinateX, y: point.coordinateY))
                }
            } catch {
                print("Ошибка загрузки точек: \(error)")
                return []
            }
        }
    
    func savePolyline(forDrawing drawingId: UUID, points: [CGPoint], closed: Bool) {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
        
        do {
            if let drawing = try context.fetch(fetchRequest).first {
                // Создаем новую полилинию
                let polyline = PolylineEntity(context: context)
                polyline.id = UUID()
                polyline.closed = closed
                
                // Сериализуем массив точек в Data (нормализованные координаты можно сохранять так же)
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: points, requiringSecureCoding: false) {
                    polyline.pointsData = data
                } else {
                    print("Ошибка сериализации точек для полилинии")
                }
                
                polyline.drawing = drawing
                saveContext()
            } else {
                print("Ошибка: Чертеж с id \(drawingId) не найден.")
            }
        } catch {
            print("Ошибка сохранения полилинии: \(error)")
        }
    }
    
    func loadPolylines(forDrawing drawingId: UUID) -> [PolylineData] {
        let fetchRequest: NSFetchRequest<PolylineEntity> = PolylineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        
        do {
            let polylineEntities = try context.fetch(fetchRequest)
            return polylineEntities.compactMap { entity in
                guard let id = entity.id,
                      let data = entity.pointsData,
                      let points = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [CGPoint]
                else { return nil }
                
                return PolylineData(id: id, points: points, closed: entity.closed)
            }
        } catch {
            print("Ошибка загрузки полилиний: \(error)")
            return []
        }
    }

    
    func saveText(forDrawing drawingId: UUID, text: String, coordinate: CGPoint) {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
        do {
            if let drawing = try context.fetch(fetchRequest).first {
                let textEntity = TextEntity(context: context)
                textEntity.id = UUID()
                textEntity.text = text
                textEntity.coordinateX = Double(coordinate.x)
                textEntity.coordinateY = Double(coordinate.y)
                textEntity.drawing = drawing
                saveContext()
            } else {
                print("Ошибка: Чертеж с id \(drawingId) не найден.")
            }
        } catch {
            print("Ошибка сохранения текстовой метки: \(error)")
        }
    }

    func loadTexts(forDrawing drawingId: UUID) -> [TextMarkerData] {
        let fetchRequest: NSFetchRequest<TextEntity> = TextEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        do {
            let textEntities = try context.fetch(fetchRequest)
            return textEntities.compactMap { textEntity in
                guard let id = textEntity.id,
                      let text = textEntity.text else { return nil }
                let coordinate = CGPoint(x: textEntity.coordinateX, y: textEntity.coordinateY)
                return TextMarkerData(id: id, text: text, coordinate: coordinate)
            }
        } catch {
            print("Ошибка загрузки текстовых меток: \(error)")
            return []
        }
    }
    
    func saveCoverImage(forProjectId projectId: UUID, image: UIImage) {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
        
        do {
            if let project = try context.fetch(fetchRequest).first {
                // Сохраняем изображение в формате PNG (вы можете использовать и JPEG, например, с jpegData(compressionQuality: 0.8))
                project.coverImageData = image.pngData()
                saveContext()
            } else {
                print("Ошибка: проект с id \(projectId) не найден.")
            }
        } catch {
            print("Ошибка сохранения обложки проекта: \(error)")
        }
    }

    func loadCoverImage(forProjectId projectId: UUID) -> UIImage? {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
        
        do {
            if let project = try context.fetch(fetchRequest).first, let data = project.coverImageData {
                return UIImage(data: data)
            }
        } catch {
            print("Ошибка загрузки обложки проекта: \(error)")
        }
        return nil
    }



}
