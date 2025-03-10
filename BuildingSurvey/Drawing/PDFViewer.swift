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







//import SwiftUI
//import PDFKit
//
//struct PDFViewer: View {
//    var pdfURL: URL?
//    var drawingId: UUID
//    @StateObject private var viewModel: DrawingViewModel
//    @State private var pdfImage: UIImage? // Переменная для хранения изображения
//
//    init(pdfURL: URL?, drawingId: UUID, repository: GeneralRepository) {
//        self.pdfURL = pdfURL
//        self.drawingId = drawingId
//        _viewModel = StateObject(wrappedValue: DrawingViewModel(drawingId: drawingId, repository: repository))
//    }
//
//    var body: some View {
//        ZStack {
//            if let pdfImage = pdfImage {
//                Image(uiImage: pdfImage)
//                    .resizable()
//                    .scaledToFit()
//                    .onAppear {
//                        print("PDF изображение загружено") // Отладочное сообщение
//                    }
//            } else {
//                Text("Нет доступного PDF")
//                    .foregroundColor(.gray)
//            }
//            DrawingCanvas(viewModel: viewModel)
//                .background(Color.clear) // Или выберите другой цвет для отладки
//
//        }
//        .navigationTitle("Чертеж")
//        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//            loadPDFImage()
//        }
//    }
//
//    private func loadPDFImage() {
//        guard let pdfURL = pdfURL, let pdfDocument = PDFDocument(url: pdfURL),
//              let pdfPage = pdfDocument.page(at: 0) else { return }
//        
//        let pdfPageRect = pdfPage.bounds(for: .mediaBox)
//        
//        // Определяем разрешение и создаем контекст
//        let scaleFactor: CGFloat = 2.0 // Увеличиваем масштаб для улучшения качества
//        let imageSize = CGSize(width: pdfPageRect.width * scaleFactor, height: pdfPageRect.height * scaleFactor)
//
//        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
//        let context = UIGraphicsGetCurrentContext()
//        context?.saveGState()
//        context?.translateBy(x: 0, y: imageSize.height)
//        context?.scaleBy(x: 1.0, y: -1.0)
//        
//        // Устанавливаем фон белым цветом
//        context?.setFillColor(UIColor.white.cgColor)
//        context?.fill(CGRect(origin: .zero, size: imageSize))
//
//        // Рисуем страницу PDF на контексте с правильным масштабом
//        context?.scaleBy(x: scaleFactor, y: scaleFactor)
//        pdfPage.draw(with: .mediaBox, to: context!)
//        context?.restoreGState()
//        
//        // Получаем изображение
//        if let image = UIGraphicsGetImageFromCurrentImageContext() {
//            pdfImage = image
//            
//            // Сохранение изображения в формате PNG
//            if let pngData = image.pngData() {
//                // Сохраните pngData в файл или используйте по своему усмотрению
//                // Например, можно сохранить в директорию документов
//                let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("drawing.png")
//                do {
//                    try pngData.write(to: filePath)
//                    print("Изображение сохранено в формате PNG по пути: \(filePath)")
//                } catch {
//                    print("Ошибка сохранения изображения: \(error)")
//                }
//            }
//        }
//        UIGraphicsEndImageContext()
//    }
//}

