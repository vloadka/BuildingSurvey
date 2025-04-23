//
//  Drawing.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 15.02.2025.
//

import Foundation

struct Drawing: Identifiable, Hashable {
    var id: UUID
    var name: String
    var filePath: String?
    var pdfData: Data?
    var scale: Double?
    var planServId: Int64?
    var projectServId: Int64?
}
