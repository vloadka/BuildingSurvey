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
    
    var currentProjects: [Project] {
        return _projectsList  // Используется уже загруженный список проектов
    }

    init() {
        loadProjects()
    }

//    func addProject(name: String, servId: String? = nil, coverImageData: Data? = nil) {
    func addProject(name: String, servId: Int? = nil, coverImageData: Data? = nil) {
        let newProject = ProjectEntity(context: context)
        newProject.id = UUID()
//        newProject.servId = servId
        newProject.servId = servId.map { NSNumber(value: $0) } as! Int64
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
                    servId: Int(projectEntity.servId),
                    name: projectEntity.name ?? "Без названия",
                    coverImageData: projectEntity.coverImageData
                )
            }
        } catch {
            print("Ошибка загрузки проектов: \(error)")
        }
    }

    func addDrawing(for project: Project, name: String, filePath: String?, pdfData: Data?) {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)

        do {
            if let projectEntity = try context.fetch(fetchRequest).first {
                let newDrawing = DrawingEntity(context: context)
                newDrawing.id = UUID()
                newDrawing.name = name
                newDrawing.filePath = filePath
                newDrawing.pdfData = pdfData
                newDrawing.project = projectEntity

                context.insert(newDrawing)
                saveContext()
                
                // ——— ЛОГИРУЕМ содержимое только что добавленного чертежа ———
                print("🗄️ Added DrawingEntity:")
                print("    • id:          \(newDrawing.id!.uuidString)")
                print("    • name:        '\(newDrawing.name ?? "")'")
                print("    • filePath:    '\(newDrawing.filePath ?? "nil")'")
                print("    • pdfDataSize: \(newDrawing.pdfData?.count ?? 0) bytes")
                
                // ——— ЛОГ: выводим всю базу чертежей ———
                let fetchAll: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
                    do {
                        let allDrawings = try context.fetch(fetchAll)
                        print("🗄️ Всего чертежей в БД: \(allDrawings.count)")
                        for drawing in allDrawings {
                            print("    • id: \(drawing.id?.uuidString ?? "nil"), name: '\(drawing.name ?? "")', filePath: '\(drawing.filePath ?? "nil")', pdfDataSize: \(drawing.pdfData?.count ?? 0) bytes")
                        }
                    } catch {
                        print("Ошибка выборки всех чертежей: \(error)")
                    }
                print("Добавлен чертеж \(name) для проекта \(project.id)")
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
            let drawings = drawingEntities.map { de in
                Drawing(
                    id: de.id ?? UUID(),
                    name: de.name ?? "Без названия",
                    filePath: de.filePath,
                    pdfData: de.pdfData 
                )
            }
            self.drawings = drawings // Обновляем список чертежей
            return drawings
        } catch {
            print("Ошибка загрузки чертежей: \(error)")
            return []
        }
    }
    
    // Метод для получения LayerEntity по идентификатору (используется для привязки объекта к слою)
    func getLayerEntity(withId id: UUID) -> LayerEntity? {
        let fetchRequest: NSFetchRequest<LayerEntity> = LayerEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(fetchRequest).first
    }
    
    // MARK: - Методы сохранения с поддержкой слоя
    
    func saveLine(forDrawing drawingId: UUID, lineId: UUID, start: CGPoint, end: CGPoint, layer: LayerData? = nil) {
            let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
            
            do {
                if let drawing = try context.fetch(fetchRequest).first {
                    let line = LineEntity(context: context)
                    // Используем переданный идентификатор вместо генерации нового
                    line.id = lineId
                    line.startX = start.x
                    line.startY = start.y
                    line.endX = end.x
                    line.endY = end.y
                    line.drawing = drawing
                    if let layerData = layer, let layerEntity = getLayerEntity(withId: layerData.id) {
                        line.layer = layerEntity
                    }
                    saveContext()
                }
            } catch {
                print("Ошибка сохранения линии: \(error)")
            }
        }
    
    func loadLines(for drawingId: UUID) -> [LineData] {
        let fetchRequest: NSFetchRequest<LineEntity> = LineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        do {
            let lines = try context.fetch(fetchRequest)
            return lines.map { line in
                let start = CGPoint(x: line.startX, y: line.startY)
                let end = CGPoint(x: line.endX, y: line.endY)
                let color = line.layer?.uiColor ?? UIColor.black
                return LineData(id: line.id ?? UUID(), start: start, end: end, color: color)
            }
        } catch {
            print("Ошибка загрузки линий: \(error)")
            return []
        }
    }


    func deleteLine(withId id: UUID) {
        let fetchRequest: NSFetchRequest<LineEntity> = LineEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let line = try context.fetch(fetchRequest).first {
                context.delete(line)
                saveContext()
            }
        } catch {
            print("Ошибка удаления линии: \(error)")
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
                photoEntity.id = id  // основной идентификатор фото-маркера
                photoEntity.imageData = image.jpegData(compressionQuality: 0.8)
                photoEntity.photoNumber = Int64(photoNumber)
                photoEntity.timestamp = timestamp
                photoEntity.coordinateX = coordinateX
                photoEntity.coordinateY = coordinateY
                // Для основного фото-маркера поле parentId оставляем nil
                photoEntity.parentId = nil
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
        // Загружаем только основные фото-маркеры (parentId == nil)
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@ AND parentId == nil", drawingId as CVarArg)
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
    
    // Возвращает новый id продвинутой фотографии, если удаляется основной фото-маркер
    func deletePhotoMarker(withId id: UUID) -> UUID? {
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let photoEntity = try context.fetch(fetchRequest).first {
                var promotedPhotoId: UUID? = nil
                // Если удаляемое фото является основным (parentId == nil)
                if photoEntity.parentId == nil {
                    // Находим дополнительные фото, связанные с этим фото-маркером
                    let additionalRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
                    additionalRequest.predicate = NSPredicate(format: "parentId == %@", id as CVarArg)
                    additionalRequest.sortDescriptors = [NSSortDescriptor(key: "photoNumber", ascending: true)]
                    let additionalPhotos = try context.fetch(additionalRequest)
                    if let firstAdditional = additionalPhotos.first {
                        // Продвигаем первую дополнительную фотографию в основное фото-маркер
                        firstAdditional.parentId = nil
                        promotedPhotoId = firstAdditional.id
                        // Перепривязываем оставшиеся дополнительные фото к продвинутой фотографии
                        for photo in additionalPhotos.dropFirst() {
                            photo.parentId = promotedPhotoId
                        }
                    }
                }
                context.delete(photoEntity)
                saveContext()
                return promotedPhotoId
            }
        } catch {
            print("Ошибка удаления фото-маркера: \(error)")
        }
        return nil
    }
    
    func updatePhotoMarker(forDrawing drawingId: UUID,
                           withId id: UUID,
                           image: UIImage,
                           timestamp: Date,
                           coordinateX: Double,
                           coordinateY: Double) {
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let photoEntity = try context.fetch(fetchRequest).first {
                photoEntity.imageData = image.jpegData(compressionQuality: 0.8)
                photoEntity.timestamp = timestamp
                photoEntity.coordinateX = coordinateX
                photoEntity.coordinateY = coordinateY
                saveContext()
            } else {
                print("Фото-маркер с id \(id) не найден.")
            }
        } catch {
            print("Ошибка обновления фото-маркера: \(error)")
        }
    }
    
    func saveAdditionalPhoto(forDrawing drawingId: UUID,
                             parentMarkerId: UUID,
                             newPhotoId: UUID,
                             image: UIImage,
                             photoNumber: Int,
                             timestamp: Date,
                             coordinateX: Double,
                             coordinateY: Double) {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
        
        do {
            if let drawing = try context.fetch(fetchRequest).first {
                let additionalPhoto = PhotoEntity(context: context)
                additionalPhoto.id = newPhotoId
                additionalPhoto.imageData = image.jpegData(compressionQuality: 0.8)
                additionalPhoto.photoNumber = Int64(photoNumber)
                additionalPhoto.timestamp = timestamp
                additionalPhoto.coordinateX = coordinateX
                additionalPhoto.coordinateY = coordinateY
                // Здесь устанавливаем связь с основным фото-маркером:
                additionalPhoto.parentId = parentMarkerId
                additionalPhoto.drawing = drawing
                saveContext()
            } else {
                print("Ошибка: Чертеж с id \(drawingId) не найден.")
            }
        } catch {
            print("Ошибка сохранения дополнительного фото: \(error)")
        }
    }
    
    func loadPhotosForMarker(withId markerId: UUID) -> [PhotoMarkerData] {
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ OR parentId == %@", markerId as CVarArg, markerId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "photoNumber", ascending: true)]
        
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
            print("Ошибка загрузки фото для маркера: \(error)")
            return []
        }
    }

    func savePoint(forDrawing drawingId: UUID, coordinate: CGPoint, layer: LayerData? = nil) -> UUID? {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
        do {
            if let drawing = try context.fetch(fetchRequest).first {
                let pointEntity = PointEntity(context: context)
                let id = UUID()  // Генерируем UUID здесь
                pointEntity.id = id
                pointEntity.coordinateX = coordinate.x
                pointEntity.coordinateY = coordinate.y
                pointEntity.drawing = drawing
                if let layerData = layer, let layerEntity = getLayerEntity(withId: layerData.id) {
                    pointEntity.layer = layerEntity
                }
                saveContext()
                return id  // Возвращаем сгенерированный UUID
            } else {
                print("Ошибка: Чертеж с id \(drawingId) не найден.")
                return nil
            }
        } catch {
            print("Ошибка сохранения точки: \(error)")
            return nil
        }
    }

    func loadPoints(forDrawing drawingId: UUID) -> [PointData] {
        let fetchRequest: NSFetchRequest<PointEntity> = PointEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        do {
            let pointEntities = try context.fetch(fetchRequest)
            return pointEntities.compactMap { entity in
                guard let id = entity.id else { return nil }
                let coordinate = CGPoint(x: entity.coordinateX, y: entity.coordinateY)
                let color = entity.layer?.uiColor ?? UIColor.blue
                return PointData(id: id, coordinate: coordinate, color: color)
            }
        } catch {
            print("Ошибка загрузки точек: \(error)")
            return []
        }
    }

    func deletePoint(withId id: UUID) {
        let fetchRequest: NSFetchRequest<PointEntity> = PointEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let point = try context.fetch(fetchRequest).first {
                context.delete(point)
                saveContext()
            }
        } catch {
            print("Ошибка удаления точки: \(error)")
        }
    }
    
    func savePolyline(forDrawing drawingId: UUID, polylineId: UUID, points: [CGPoint], closed: Bool, layer: LayerData? = nil) {
            let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
            
            do {
                if let drawing = try context.fetch(fetchRequest).first {
                    let polyline = PolylineEntity(context: context)
                    // Используем переданный идентификатор
                    polyline.id = polylineId
                    polyline.closed = closed
                    if let data = try? NSKeyedArchiver.archivedData(withRootObject: points, requiringSecureCoding: false) {
                        polyline.pointsData = data
                    }
                    polyline.drawing = drawing
                    if let layerData = layer, let layerEntity = getLayerEntity(withId: layerData.id) {
                        polyline.layer = layerEntity
                    }
                    saveContext()
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
                guard let data = entity.pointsData,
                      let points = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [CGPoint],
                      let id = entity.id else { return nil }
                let color = entity.layer?.uiColor ?? UIColor.green
                return PolylineData(id: id, points: points, closed: entity.closed, color: color)
            }
        } catch {
            print("Ошибка загрузки полилиний: \(error)")
            return []
        }
    }

    func deletePolyline(withId id: UUID) {
           let fetchRequest: NSFetchRequest<PolylineEntity> = PolylineEntity.fetchRequest()
           fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
           do {
               if let polyline = try context.fetch(fetchRequest).first {
                   context.delete(polyline)
                   saveContext()
               }
           } catch {
               print("Ошибка удаления полилинии: \(error)")
           }
       }
    
    func saveText(forDrawing drawingId: UUID, text: String, coordinate: CGPoint, layer: LayerData? = nil) {
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
                if let layerData = layer, let layerEntity = getLayerEntity(withId: layerData.id) {
                    textEntity.layer = layerEntity
                }
                saveContext()
            } else {
                print("Ошибка: Чертеж с id \(drawingId) не найден.")
            }
        } catch {
            print("Ошибка сохранения текстовой метки: \(error)")
        }
    }

    func loadTexts(forDrawing drawingId: UUID) -> [TextData] {
        let fetchRequest: NSFetchRequest<TextEntity> = TextEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        do {
            let textEntities = try context.fetch(fetchRequest)
            return textEntities.compactMap { entity in
                guard let id = entity.id, let text = entity.text else { return nil }
                let coordinate = CGPoint(x: entity.coordinateX, y: entity.coordinateY)
                let color = entity.layer?.uiColor ?? UIColor.blue
                return TextData(id: id, text: text, coordinate: coordinate, color: color)
            }
        } catch {
            print("Ошибка загрузки текстовых меток: \(error)")
            return []
        }
    }

    
    func deleteText(withId id: UUID) {
        let fetchRequest: NSFetchRequest<TextEntity> = TextEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let text = try context.fetch(fetchRequest).first {
                context.delete(text)
                saveContext()
            }
        } catch {
            print("Ошибка удаления текстовой метки: \(error)")
        }
    }

    func saveCoverImage(forProjectId projectId: UUID, image: UIImage) {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
        
        do {
            if let project = try context.fetch(fetchRequest).first {
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

    // Загрузка слоёв для заданного проекта
    func loadLayers(forProject project: Project) -> [LayerEntity] {
        let fetchRequest: NSFetchRequest<LayerEntity> = LayerEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project.id == %@", project.id as CVarArg)
        
        do {
            let layers = try context.fetch(fetchRequest)
            return layers
        } catch {
            print("Ошибка загрузки слоёв: \(error)")
            return []
        }
    }
    
    // Сохранение нового слоя для заданного проекта.
    // Здесь передаются название и цвет слоя.
    func saveLayer(forProject project: Project, layer: LayerData) {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)
        
        do {
            if let projectEntity = try context.fetch(fetchRequest).first {
                let newLayer = LayerEntity(context: context)
                newLayer.id = layer.id
                newLayer.name = layer.name
                newLayer.colorHex = layer.color.toHex()
                newLayer.timestamp = Date()
                newLayer.setValue(projectEntity, forKey: "project")
                saveContext()
            } else {
                print("Ошибка: проект не найден при сохранении слоя")
            }
        } catch {
            print("Ошибка сохранения слоя: \(error)")
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
            let maxNumber = photos.map { Int($0.photoNumber) }.max() ?? 0
            return maxNumber + 1
        } catch {
            print("Ошибка получения номера фото: \(error)")
            return 1
        }
    }
    
    // Сохранение прямоугольника для чертежа
    func saveRectangle(forDrawing drawingId: UUID, rect: CGRect, layer: LayerData? = nil) {
        let fetchRequest: NSFetchRequest<DrawingEntity> = DrawingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawingId as CVarArg)
        
        do {
            if let drawing = try context.fetch(fetchRequest).first {
                let rectangle = RectangleEntity(context: context)
                rectangle.id = UUID()
                rectangle.x = Double(rect.origin.x)
                rectangle.y = Double(rect.origin.y)
                rectangle.width = Double(rect.size.width)
                rectangle.height = Double(rect.size.height)
                rectangle.drawing = drawing
                if let layerData = layer, let layerEntity = getLayerEntity(withId: layerData.id) {
                    rectangle.layer = layerEntity
                }
                saveContext()
            }
        } catch {
            print("Ошибка сохранения прямоугольника: \(error)")
        }
    }


    // Загрузка прямоугольников для заданного чертежа
    func loadRectangles(forDrawing drawingId: UUID) -> [RectangleData] {
        let fetchRequest: NSFetchRequest<RectangleEntity> = RectangleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "drawing.id == %@", drawingId as CVarArg)
        do {
            let rectangleEntities = try context.fetch(fetchRequest)
            return rectangleEntities.compactMap { rectangle in
                guard let id = rectangle.id else { return nil }
                let rect = CGRect(x: rectangle.x, y: rectangle.y, width: rectangle.width, height: rectangle.height)
                let color = rectangle.layer?.uiColor ?? UIColor.red
                return RectangleData(id: id, rect: rect, color: color)
            }
        } catch {
            print("Ошибка загрузки прямоугольников: \(error)")
            return []
        }
    }

    func deleteRectangle(withId id: UUID) {
        let fetchRequest: NSFetchRequest<RectangleEntity> = RectangleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let rect = try context.fetch(fetchRequest).first {
                context.delete(rect)
                saveContext()
            }
        } catch {
            print("Ошибка удаления прямоугольника: \(error)")
        }
    }
    
    // Добавляем функции удаления для объектов, привязанных к слою
    func deleteLines(forLayer layer: LayerEntity) {
        for line in layer.linesArray {
            context.delete(line)
        }
    }

    func deletePoints(forLayer layer: LayerEntity) {
        for point in layer.pointsArray {
            context.delete(point)
        }
    }

    func deletePolylines(forLayer layer: LayerEntity) {
        for polyline in layer.polylinesArray {
            context.delete(polyline)
        }
    }

    func deleteRectangles(forLayer layer: LayerEntity) {
        for rectangle in layer.rectanglesArray {
            context.delete(rectangle)
        }
    }

    func deleteTexts(forLayer layer: LayerEntity) {
        for text in layer.textsArray {
            context.delete(text)
        }
    }

    // Обновлённый метод удаления слоя
    func deleteLayer(withId id: UUID) {
        let fetchRequest: NSFetchRequest<LayerEntity> = LayerEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let layer = try context.fetch(fetchRequest).first {
                // Удаляем все объекты, связанные с этим слоем
                deleteLines(forLayer: layer)
                deletePoints(forLayer: layer)
                deletePolylines(forLayer: layer)
                deleteRectangles(forLayer: layer)
                deleteTexts(forLayer: layer)
                // Затем удаляем сам слой
                context.delete(layer)
                saveContext()
            }
        } catch {
            print("Ошибка удаления слоя: \(error)")
        }
    }
    
    func saveAudio(forProject project: Project, audioData: Data, timestamp: Date, drawingName: String) {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)
        
        do {
            if let projectEntity = try context.fetch(fetchRequest).first {
                let audioEntity = AudioEntity(context: context)
                audioEntity.id = UUID()
                audioEntity.audioData = audioData
                audioEntity.timestamp = timestamp
                audioEntity.drawingName = drawingName  // сохраняем название чертежа
                audioEntity.project = projectEntity
                saveContext()
            }
        } catch {
            print("Ошибка сохранения аудио: \(error)")
        }
    }


    func loadAudio(for project: Project) -> [AudioNote] {
        let fetchRequest: NSFetchRequest<AudioEntity> = AudioEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project.id == %@", project.id as CVarArg)
        do {
            let audioEntities = try context.fetch(fetchRequest)
            return audioEntities.compactMap { entity in
                guard let id = entity.id,
                      let audioData = entity.audioData,
                      let timestamp = entity.timestamp else {
                    return nil
                }
                return AudioNote(id: id, audioData: audioData, timestamp: timestamp, drawingName: entity.drawingName ?? "")
            }
        } catch {
            print("Ошибка загрузки аудио: \(error)")
            return []
        }
    }

    func deleteAudio(withId id: UUID) {
        let fetchRequest: NSFetchRequest<AudioEntity> = AudioEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                saveContext()
            }
        } catch {
            print("Ошибка удаления аудио: \(error)")
        }
    }
    
    func checkAdditionalPhoto(forMarkerId markerId: UUID, using repository: GeneralRepository) {
        let photos = repository.loadPhotosForMarker(withId: markerId)
        if photos.count > 1 {
            print("Фото-маркер с id \(markerId) содержит дополнительное фото. Всего фото: \(photos.count)")
        } else {
            print("Фото-маркер с id \(markerId) не имеет дополнительного фото.")
        }
    }

}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        var r, g, b, a: UInt64
        switch length {
        case 6: // RRGGBB
            (r, g, b, a) = (rgb >> 16 & 0xFF, rgb >> 8 & 0xFF, rgb & 0xFF, 255)
        case 8: // RRGGBBAA
            (r, g, b, a) = (rgb >> 24 & 0xFF, rgb >> 16 & 0xFF, rgb >> 8 & 0xFF, rgb & 0xFF)
        default:
            return nil
        }
        
        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: CGFloat(a) / 255)
    }
    
    
    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if alpha {
            return String(format: "#%02lX%02lX%02lX%02lX",
                          lroundf(r * 255),
                          lroundf(g * 255),
                          lroundf(b * 255),
                          lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                          lroundf(r * 255),
                          lroundf(g * 255),
                          lroundf(b * 255))
        }
    }
}
