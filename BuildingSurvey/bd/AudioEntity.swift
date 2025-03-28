//
//  AudioEntity.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 26.03.2025.
//

import CoreData

@objc(AudioEntity)
public class AudioEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var audioData: Data?
    @NSManaged public var timestamp: Date?
    // Если требуется привязка аудио к проекту, можно добавить связь:
    @NSManaged public var project: ProjectEntity?
}

extension AudioEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AudioEntity> {
        return NSFetchRequest<AudioEntity>(entityName: "AudioEntity")
    }
}


