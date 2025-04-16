//
//  ProjectEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 07.02.2025.
//
import CoreData

@objc(ProjectEntity)
public class ProjectEntity: NSManagedObject {
    @NSManaged public var id: UUID?
//    @NSManaged public var servId: String?
    @NSManaged public var servId: Int64
    @NSManaged public var name: String?
    //@NSManaged public var projectFilePath: String?
    @NSManaged public var drawings: Set<DrawingEntity>?
    @NSManaged public var coverImageData: Data?
}
