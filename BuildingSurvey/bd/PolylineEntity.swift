//
//  PolylineEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 14.03.2025.
//

import CoreData

@objc(PolylineEntity)
public class PolylineEntity: NSManagedObject {    
    @NSManaged public var id: UUID?
    @NSManaged public var pointsData: Data?
    @NSManaged public var closed: Bool
    @NSManaged public var drawing: DrawingEntity?
    @NSManaged public var layer: LayerEntity? // Новое свойство для привязки к слою
}

extension PolylineEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PolylineEntity> {
        return NSFetchRequest<PolylineEntity>(entityName: "PolylineEntity")
    }
}
