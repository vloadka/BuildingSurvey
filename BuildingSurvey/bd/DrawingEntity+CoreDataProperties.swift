//
//  DrawingEntity+CoreDataProperties.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 15.02.2025.
//

import CoreData

extension DrawingEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrawingEntity> {
        return NSFetchRequest<DrawingEntity>(entityName: "DrawingEntity")
    }
}
