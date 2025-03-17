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
    // Добавляем связь с проектом
    @NSManaged public var project: ProjectEntity?
}

extension LayerEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LayerEntity> {
        return NSFetchRequest<LayerEntity>(entityName: "LayerEntity")
    }
    
    // Вспомогательное свойство для получения UIColor из colorHex
    public var uiColor: UIColor? {
        guard let hex = colorHex else { return nil }
        return UIColor(named: hex)
    }
}
