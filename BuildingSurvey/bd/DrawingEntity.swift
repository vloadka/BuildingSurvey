//
//  DrawingEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 15.02.2025.
//

import CoreData

@objc(DrawingEntity)
public class DrawingEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var filePath: String?
    @NSManaged public var pdfData: Data?
    @NSManaged public var project: ProjectEntity?
    

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = DrawingEntity(context: self.managedObjectContext!)
        copy.id = self.id
        copy.name = self.name
        copy.filePath = self.filePath
        copy.pdfData = self.pdfData
        copy.project = self.project
        return copy
    }
}
