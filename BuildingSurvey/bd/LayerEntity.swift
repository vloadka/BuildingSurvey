//
//  LayerEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 14.03.2025.
//

import Foundation
import CoreData
import UIKit

@objc(LayerEntity)
public class LayerEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    // Храним цвет в виде HEX-строки для простоты
    @NSManaged public var colorHex: String?
    @NSManaged public var timestamp: Date?
    // Связь с проектом
    @NSManaged public var project: ProjectEntity?
    
    // Обратные отношения – все объекты, связанные с этим слоем
    @NSManaged public var lines: NSSet?
    @NSManaged public var points: NSSet?
    @NSManaged public var polylines: NSSet?
    @NSManaged public var rectangles: NSSet?
    @NSManaged public var texts: NSSet?
}

extension LayerEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LayerEntity> {
        return NSFetchRequest<LayerEntity>(entityName: "LayerEntity")
    }
    
    // Вспомогательное свойство для получения UIColor из colorHex
    public var uiColor: UIColor? {
        guard let hex = colorHex else { return nil }
        return UIColor(hex: hex)
    }
    
    // Вычисляемые свойства для удобства доступа к связанным объектам
    public var linesArray: [LineEntity] {
        return lines?.allObjects as? [LineEntity] ?? []
    }

    
    public var pointsArray: [PointEntity] {
        return points?.allObjects as? [PointEntity] ?? []
    }
    
    public var polylinesArray: [PolylineEntity] {
        return polylines?.allObjects as? [PolylineEntity] ?? []
    }
    
    public var rectanglesArray: [RectangleEntity] {
        return rectangles?.allObjects as? [RectangleEntity] ?? []
    }
    
    public var textsArray: [TextEntity] {
        return texts?.allObjects as? [TextEntity] ?? []
    }
}
