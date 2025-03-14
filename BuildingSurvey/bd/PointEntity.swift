//
//  PointEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 12.03.2025.
//

import CoreData

@objc(PointEntity)
public class PointEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var coordinateX: Double
    @NSManaged public var coordinateY: Double
    @NSManaged public var drawing: DrawingEntity?
}

extension PointEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PointEntity> {
        return NSFetchRequest<PointEntity>(entityName: "PointEntity")
    }
}

