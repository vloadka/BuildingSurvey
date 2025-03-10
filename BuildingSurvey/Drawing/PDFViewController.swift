//
//  PDFViewController.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 05.03.2025.
//

import UIKit
import CoreGraphics

// Класс для маркера с фотографией
class PhotoMarkerButton: UIButton {
    var photo: UIImage?
    var photoEntityId: UUID?
    var normalizedCoordinate: CGPoint?  // Новое свойство для фиксированных координат
}


struct PhotoMarkerData {
    let id: UUID
    let image: UIImage
    let coordinate: CGPoint
}

class PDFViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let pdfURL: URL
    private let drawingId: UUID
    private let repository: GeneralRepository

    private var drawingView: DrawingView!
    private var pdfImageView: UIImageView!
    private var drawingToggleButton: UIButton!
    private var drawingEnabled: Bool = false
    
    private var topPanel: UIView!
    private var bottomPanel: UIView!
    
    // Кнопка для переключения фото-режима в верхней панели
    private var topToggleButton: UIButton!
    private var topButtonActive: Bool = false
    
    // Распознаватель для установки фото-маркера (в фото-режиме)
    private var photoMarkerTapRecognizer: UITapGestureRecognizer!
    // Ссылка на текущий маркер, для которого делается фото
    private var currentPhotoMarker: PhotoMarkerButton?
    
    private var currentViewingMarker: PhotoMarkerButton?


    init(pdfURL: URL, drawingId: UUID, repository: GeneralRepository) {
        self.pdfURL = pdfURL
        self.drawingId = drawingId
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Настроим навигацию
        navigationItem.largeTitleDisplayMode = .always
        
        // Создаем панели для иконок
        let panelHeight: CGFloat = 60.0
        
        topPanel = UIView()
        topPanel.translatesAutoresizingMaskIntoConstraints = false
        topPanel.backgroundColor = .white // Непрозрачный фон
        view.addSubview(topPanel)
        
        bottomPanel = UIView()
        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.backgroundColor = .white // Непрозрачный фон
        view.addSubview(bottomPanel)
        
        NSLayoutConstraint.activate([
            // Верхняя панель
            topPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPanel.heightAnchor.constraint(equalToConstant: panelHeight),
            // Нижняя панель
            bottomPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.heightAnchor.constraint(equalToConstant: panelHeight)
        ])
        
        // Создаем UIImageView для отображения PDF и располагаем его между панелями
        pdfImageView = UIImageView()
        pdfImageView.translatesAutoresizingMaskIntoConstraints = false
        pdfImageView.contentMode = .scaleAspectFit
        if let pdfImage = renderPDFtoImage(url: pdfURL) {
            pdfImageView.image = pdfImage
        }
        view.addSubview(pdfImageView)
        
        NSLayoutConstraint.activate([
            pdfImageView.topAnchor.constraint(equalTo: topPanel.bottomAnchor),
            pdfImageView.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor),
            pdfImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Настроим DrawingView, который располагается поверх pdfImageView
        drawingView = DrawingView(frame: .zero)
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.backgroundColor = .clear
        drawingView.onLineDrawn = { [weak self] start, end in
            guard let self = self else { return }
            self.repository.saveLine(for: self.drawingId, start: start, end: end)
        }
        // Изначально режим рисования выключен
        drawingView.isUserInteractionEnabled = false
        view.addSubview(drawingView)
        
        NSLayoutConstraint.activate([
            drawingView.topAnchor.constraint(equalTo: pdfImageView.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: pdfImageView.bottomAnchor),
            drawingView.leadingAnchor.constraint(equalTo: pdfImageView.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: pdfImageView.trailingAnchor)
        ])
        
        // Загружаем сохраненные линии и преобразуем их в тип Line
        let savedLines = repository.loadLines(for: drawingId)
        let lineObjects = savedLines.map { Line(start: $0.0, end: $0.1) }
        drawingView.loadLines(lineObjects)
        
        // Добавляем кнопку для переключения режима рисования в нижней панели
        drawingToggleButton = UIButton(type: .custom)
        drawingToggleButton.translatesAutoresizingMaskIntoConstraints = false
        drawingToggleButton.setImage(UIImage(named: "Line_passive"), for: .normal)
        drawingToggleButton.addTarget(self, action: #selector(toggleDrawingMode(_:)), for: .touchUpInside)
        bottomPanel.addSubview(drawingToggleButton)
        
        NSLayoutConstraint.activate([
            drawingToggleButton.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            drawingToggleButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            drawingToggleButton.heightAnchor.constraint(equalToConstant: 44),
            drawingToggleButton.widthAnchor.constraint(equalToConstant: 44)
        ])
        
        // Добавляем иконку (например, меню) в верхней панели
        let topIconButton = UIButton(type: .custom)
        topIconButton.translatesAutoresizingMaskIntoConstraints = false
        topIconButton.setImage(UIImage(named: "settings"), for: .normal)
        topPanel.addSubview(topIconButton)
        
        NSLayoutConstraint.activate([
            topIconButton.leadingAnchor.constraint(equalTo: topPanel.leadingAnchor, constant: 16),
            topIconButton.centerYAnchor.constraint(equalTo: topPanel.centerYAnchor),
            topIconButton.heightAnchor.constraint(equalToConstant: 30),
            topIconButton.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        // Добавляем дополнительную кнопку в верхней панели для фото-режима
        topToggleButton = UIButton(type: .custom)
        topToggleButton.translatesAutoresizingMaskIntoConstraints = false
        topToggleButton.setImage(UIImage(named: "Photo_passive_1"), for: .normal)
        topToggleButton.addTarget(self, action: #selector(toggleTopButtonMode(_:)), for: .touchUpInside)
        topPanel.addSubview(topToggleButton)
        
        NSLayoutConstraint.activate([
            topToggleButton.trailingAnchor.constraint(equalTo: topPanel.trailingAnchor, constant: -16),
            topToggleButton.centerYAnchor.constraint(equalTo: topPanel.centerYAnchor),
            topToggleButton.heightAnchor.constraint(equalToConstant: 30),
            topToggleButton.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        // Инициализируем распознаватель тапа для установки фото-маркера (по умолчанию отключен)
        photoMarkerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePhotoMarkerTap(_:)))
        photoMarkerTapRecognizer.isEnabled = false
        view.addGestureRecognizer(photoMarkerTapRecognizer)
        
        loadPhotoMarkers()
    }
    
    // MARK: - Режим рисования (нижняя кнопка)
    @objc private func toggleDrawingMode(_ sender: UIButton) {
        drawingEnabled.toggle()
        drawingView.isUserInteractionEnabled = drawingEnabled
        let imageName = drawingEnabled ? "Line_active" : "Line_passive"
        drawingToggleButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    // MARK: - Режим фото (верхняя кнопка)
    @objc private func toggleTopButtonMode(_ sender: UIButton) {
        topButtonActive.toggle()
        let imageName = topButtonActive ? "Photo_active_1" : "Photo_passive_1"
        topToggleButton.setImage(UIImage(named: imageName), for: .normal)
        // Включаем или отключаем возможность установки фото-маркера
        photoMarkerTapRecognizer.isEnabled = topButtonActive
    }
    
    // MARK: - Установка фото-маркера
    @objc private func handlePhotoMarkerTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        let markerSize: CGFloat = 30.0
        let markerFrame = CGRect(x: location.x - markerSize/2, y: location.y - markerSize/2, width: markerSize, height: markerSize)
        let markerButton = PhotoMarkerButton(frame: markerFrame)
        markerButton.backgroundColor = .red
        markerButton.layer.cornerRadius = markerSize / 2
        markerButton.clipsToBounds = true
        markerButton.addTarget(self, action: #selector(photoMarkerTapped(_:)), for: .touchUpInside)
        view.addSubview(markerButton)
        view.bringSubviewToFront(markerButton)
        
        // Обновляем layout, чтобы размеры pdfImageView были корректными
        view.layoutIfNeeded()
        // Фиксируем координаты в системе pdfImageView
        let markerCenterInPDF = pdfImageView.convert(markerButton.center, from: view)
        let normalizedX = markerCenterInPDF.x / pdfImageView.bounds.width
        let normalizedY = markerCenterInPDF.y / pdfImageView.bounds.height
        markerButton.normalizedCoordinate = CGPoint(x: normalizedX, y: normalizedY)
        
        currentPhotoMarker = markerButton
        photoMarkerTapRecognizer.isEnabled = false
        presentCamera()
    }

    
    // MARK: - Запуск камеры
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            // Если камера недоступна, можно вывести alert или выполнить другой код
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage,
              let marker = currentPhotoMarker,
              let normalized = marker.normalizedCoordinate else { return }
        
        // Генерируем уникальный идентификатор для метки и сохраняем его в кнопке
        let markerId = UUID()
        marker.photoEntityId = markerId
        
        let photoNumber = repository.getNextPhotoNumber(forDrawing: drawingId)
        
        // Сохраняем фото-маркер с зафиксированными нормализованными координатами
        repository.savePhotoMarker(forDrawing: drawingId,
                                   withId: markerId,
                                   image: image,
                                   photoNumber: photoNumber,
                                   timestamp: Date(),
                                   coordinateX: Double(normalized.x),
                                   coordinateY: Double(normalized.y))
        
        // Обновляем внешний вид метки
        marker.photo = image
        marker.setBackgroundImage(image, for: .normal)
        
        currentPhotoMarker = nil
        photoMarkerTapRecognizer.isEnabled = topButtonActive
    }



    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        // Если пользователь отменил съемку, удаляем созданный маркер
        currentPhotoMarker?.removeFromSuperview()
        currentPhotoMarker = nil
        photoMarkerTapRecognizer.isEnabled = topButtonActive
    }
    
    // MARK: - Обработка нажатия на фото-маркер
    @objc private func photoMarkerTapped(_ sender: PhotoMarkerButton) {
        guard let photo = sender.photo else { return }
        presentPhoto(photo, forMarker: sender)
    }

    
    // Отображение фотографии в полном экране
    private func presentPhoto(_ image: UIImage, forMarker marker: PhotoMarkerButton) {
        let photoVC = UIViewController()
        photoVC.view.backgroundColor = .black
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        photoVC.view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: photoVC.view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: photoVC.view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: photoVC.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor)
        ])
        
        // Кнопка закрыть
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissPhotoVC), for: .touchUpInside)
        photoVC.view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor, constant: -16)
        ])
        
        // Кнопка удалить
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Удалить", for: .normal)
        deleteButton.tintColor = .red
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deletePhotoMarkerAction(_:)), for: .touchUpInside)
        photoVC.view.addSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.bottomAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            deleteButton.centerXAnchor.constraint(equalTo: photoVC.view.centerXAnchor)
        ])
        
        // Сохраняем ссылку на текущую метку для удаления
        self.currentViewingMarker = marker
        
        present(photoVC, animated: true)
    }

    
    @objc private func dismissPhotoVC() {
        dismiss(animated: true)
    }
    
    // MARK: - Рендер PDF
    func renderPDFtoImage(url: URL) -> UIImage? {
        guard let pdfDocument = CGPDFDocument(url as CFURL),
              let page = pdfDocument.page(at: 1) else {
            return nil
        }
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            ctx.cgContext.drawPDFPage(page)
        }
    }
    
    private func loadPhotoMarkers() {
        let markers = repository.loadPhotoMarkers(forDrawing: drawingId)
        let markerSize: CGFloat = 30.0
        view.layoutIfNeeded()
        let pdfFrame = pdfImageView.frame
        
        for markerData in markers {
            let markerButton = PhotoMarkerButton(frame: CGRect(x: 0, y: 0, width: markerSize, height: markerSize))
            markerButton.photo = markerData.image
            markerButton.setBackgroundImage(markerData.image, for: .normal)
            markerButton.backgroundColor = .red
            markerButton.layer.cornerRadius = markerSize / 2
            markerButton.clipsToBounds = true
            markerButton.addTarget(self, action: #selector(photoMarkerTapped(_:)), for: .touchUpInside)
            
            // Сохраняем идентификатор для возможности удаления
            markerButton.photoEntityId = markerData.id
            // Сохраняем нормализованные координаты, если понадобится
            markerButton.normalizedCoordinate = markerData.coordinate
            
            // Вычисляем абсолютное положение на основе нормализованных координат
            let centerX = pdfFrame.origin.x + markerData.coordinate.x * pdfFrame.width
            let centerY = pdfFrame.origin.y + markerData.coordinate.y * pdfFrame.height
            markerButton.center = CGPoint(x: centerX, y: centerY)
            
            view.addSubview(markerButton)
            view.bringSubviewToFront(markerButton)
        }
    }




    
    @objc private func deletePhotoMarkerAction(_ sender: UIButton) {
        guard let marker = currentViewingMarker, let markerId = marker.photoEntityId else {
            return
        }
        repository.deletePhotoMarker(withId: markerId)
        marker.removeFromSuperview()
        dismiss(animated: true)
    }

}
