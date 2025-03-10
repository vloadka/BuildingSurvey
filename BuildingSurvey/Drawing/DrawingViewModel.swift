//
//  DrawingViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 21.02.2025.
//

//import SwiftUI
//import Combine
//
//class DrawingViewModel: ObservableObject {
//    @Published var lines: [[CGPoint]] = [] // Список линий (по 2 точки в каждой)
//    private var currentLine: [CGPoint] = []
//    
//    private var repository: GeneralRepository
//    private var drawingId: UUID
//    
//    init(drawingId: UUID, repository: GeneralRepository) {
//        self.drawingId = drawingId
//        self.repository = repository
//        loadAnnotations()
//    }
//    
//    func addPoint(_ point: CGPoint) {
//        if currentLine.count < 2 {
//            currentLine.append(point)
//            print("Точка добавлена: \(point)") // Отладочное сообщение
//
//            // Если у нас 2 точки, добавляем линию и сбрасываем текущее
//            if currentLine.count == 2 {
//                objectWillChange.send()
//                lines.append(currentLine)
//                print("Линия добавлена: \(currentLine)") // Отладочное сообщение
//                saveCurrentLine() // Сохраните текущую линию
//                currentLine = []
//            }
//        } else {
//            // Если текущая линия уже полна, сбрасываем её и начинаем новую
//            currentLine = [point]
//            print("Начата новая линия с точки: \(point)") // Отладочное сообщение
//        }
//    }
//
//    
//    private func loadAnnotations() {
//        let annotations = repository.loadAnnotations(for: drawingId)
//        print("Загруженные аннотации: \(annotations)") // Отладочное сообщение
//        lines = annotations.map { $0.getPoints() }
//    }
//    
//    private func saveCurrentLine() {
//        guard let lastLine = lines.last, lastLine.count == 2 else { return }
//        repository.addAnnotation(to: drawingId, points: lastLine)
//    }
//}
//
//
//
////import Foundation
////import SwiftUI
////
////class DrawingViewModel: ObservableObject {
////    @Published var annotations: [Annotation] = []
////    
////    private let repository: GeneralRepository
////    let drawingId: UUID
////
////    init(drawingId: UUID, repository: GeneralRepository) {
////        self.drawingId = drawingId
////        self.repository = repository
////        loadAnnotations()
////    }
////    
////    func addAnnotation(_ annotation: Annotation) {
////        annotations.append(annotation)
////        saveAnnotations()
////    }
////    
////    func removeAnnotation(_ annotation: Annotation) {
////        annotations.removeAll { $0.id == annotation.id }
////        saveAnnotations()
////    }
////
////    private func saveAnnotations() {
////        repository.saveAnnotations(for: drawingId, annotations: annotations)
////    }
////
////    private func loadAnnotations() {
////        annotations = repository.loadAnnotations(for: drawingId)
////    }
////}

