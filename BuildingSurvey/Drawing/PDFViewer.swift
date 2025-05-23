//
//  PDFViewer.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 19.02.2025.
//

import SwiftUI
import UIKit

struct PDFViewer: UIViewControllerRepresentable {
    let pdfURL: URL
    let drawingId: UUID
    let repository: GeneralRepository
    let project: Project
    let scale: Double

    func makeUIViewController(context: Context) -> PDFViewController {
        let vc = PDFViewController(pdfURL: pdfURL, drawingId: drawingId, repository: repository, project: project, scale: scale)
        return vc
    }

    func updateUIViewController(_ uiViewController: PDFViewController, context: Context) {}
}
