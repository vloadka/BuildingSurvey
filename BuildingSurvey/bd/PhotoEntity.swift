//
//  PhotoEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 07.03.2025.
//

import CoreData

@objc(PhotoEntity)
public class PhotoEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var imageData: Data?
    @NSManaged public var photoNumber: Int64
    @NSManaged public var timestamp: Date?
    @NSManaged public var coordinateX: Double
    @NSManaged public var coordinateY: Double
    @NSManaged public var parentId: UUID?
    @NSManaged public var drawing: DrawingEntity?
}

extension PhotoEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoEntity> {
        return NSFetchRequest<PhotoEntity>(entityName: "PhotoEntity")
    }
}
