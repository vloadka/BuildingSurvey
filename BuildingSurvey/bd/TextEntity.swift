//
//  TextEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 14.03.2025.
//

import CoreData

@objc(TextEntity)
public class TextEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var coordinateX: Double
    @NSManaged public var coordinateY: Double
    @NSManaged public var drawing: DrawingEntity?
    @NSManaged public var layer: LayerEntity? 
}

extension TextEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextEntity> {
        return NSFetchRequest<TextEntity>(entityName: "TextEntity")
    }
}
