//
//  Project.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import Foundation

struct Project: Identifiable {
    var id = UUID()
    var name: String
    var isDeleted: Int = 0
    var projectFilePath: String? // Хранение пути к файлу обложки
}
