//
//  LineEntity+CoreDataProperties.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 05.03.2025.
//

import CoreData

extension LineEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LineEntity> {
        return NSFetchRequest<LineEntity>(entityName: "LineEntity")
    }
}
