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

    func makeUIViewController(context: Context) -> PDFViewController {
        let vc = PDFViewController(pdfURL: pdfURL, drawingId: drawingId, repository: repository)
        return vc
    }

    func updateUIViewController(_ uiViewController: PDFViewController, context: Context) {}
}
