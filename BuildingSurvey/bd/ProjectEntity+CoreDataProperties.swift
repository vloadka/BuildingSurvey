//
//  ProjectEntity+CoreDataProperties.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 07.02.2025.
//

import CoreData

extension ProjectEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectEntity> {
        return NSFetchRequest<ProjectEntity>(entityName: "ProjectEntity")
    }
}
