//
//  CoreDataManager.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 07.02.2025.
//

import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "ProjectModel")
        
        // Включаем легковесную миграцию
        if let storeDescription = persistentContainer.persistentStoreDescriptions.first {
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Ошибка загрузки хранилища Core Data: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения в Core Data: \(error)")
            }
        }
    }
}
