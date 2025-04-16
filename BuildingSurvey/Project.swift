//
//  Project.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import Foundation

struct Project: Identifiable, Hashable {
    var id = UUID()
//    var servId: String? = nil
    var servId: Int? = nil
    var name: String
    var coverImageData: Data?
}
