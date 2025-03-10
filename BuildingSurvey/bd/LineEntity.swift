//
//  LineEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 05.03.2025.
//

import CoreData

@objc(LineEntity)
public class LineEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var startX: Double
    @NSManaged public var startY: Double
    @NSManaged public var endX: Double
    @NSManaged public var endY: Double
    @NSManaged public var drawing: DrawingEntity?
}
