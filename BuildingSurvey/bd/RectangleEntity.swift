//
//  RectangleEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 19.03.2025.
//

import CoreData

@objc(RectangleEntity)
public class RectangleEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var x: Double
    @NSManaged public var y: Double
    @NSManaged public var width: Double
    @NSManaged public var height: Double
    @NSManaged public var drawing: DrawingEntity?
    @NSManaged public var layer: LayerEntity? // Новое свойство для привязки к слою
}

extension RectangleEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RectangleEntity> {
        return NSFetchRequest<RectangleEntity>(entityName: "RectangleEntity")
    }
}
