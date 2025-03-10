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
    var normalizedCoordinate: CGPoint?  // Свойство для фиксированных координат
}

struct PhotoMarkerData {
    let id: UUID
    let image: UIImage
    let coordinate: CGPoint
}

class PDFViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    private let pdfURL: URL
    private let drawingId: UUID
    private let repository: GeneralRepository

    private var pdfScrollView: UIScrollView!
    private var pdfContentView: UIView!
    private var pdfImageView: UIImageView!
    private var drawingView: DrawingView!
    
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
    
    // Флаг, чтобы маркеры загружались только один раз после установки размеров
    private var markersLoaded = false
    
    // Ключ для сохранения зума в UserDefaults
    private var zoomScaleKey: String {
        return "pdfZoomScale_\(drawingId.uuidString)"
    }
    
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
        
        navigationItem.largeTitleDisplayMode = .always
        
        setupPanels()
        setupScrollViewAndContent()
        setupPDFAndDrawingViews()
        setupButtons()
        setupPhotoMarkerTapRecognizer()
        
        loadSavedLines()
        // Загрузка маркеров происходит в viewDidLayoutSubviews, когда размеры установлены
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Вычисляем минимальный масштаб, чтобы PDF полностью помещался на экране
        let scrollSize = pdfScrollView.bounds.size
        let contentSize = pdfContentView.bounds.size
        if contentSize.width > 0 && contentSize.height > 0 {
            let widthScale = scrollSize.width / contentSize.width
            let heightScale = scrollSize.height / contentSize.height
            let minScale = min(widthScale, heightScale)
            pdfScrollView.minimumZoomScale = minScale
            // Если текущий зум меньше минимального, устанавливаем его
            if pdfScrollView.zoomScale < minScale {
                pdfScrollView.zoomScale = minScale
            }
        }
        
        if !markersLoaded {
            pdfContentView.layoutIfNeeded()
            loadPhotoMarkers()
            markersLoaded = true
        }
    }
    
    // MARK: - Настройка интерфейса
    private func setupPanels() {
        let panelHeight: CGFloat = 60.0
        
        topPanel = UIView()
        topPanel.translatesAutoresizingMaskIntoConstraints = false
        topPanel.backgroundColor = .white
        view.addSubview(topPanel)
        
        bottomPanel = UIView()
        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.backgroundColor = .white
        view.addSubview(bottomPanel)
        
        NSLayoutConstraint.activate([
            topPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPanel.heightAnchor.constraint(equalToConstant: panelHeight),
            
            bottomPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.heightAnchor.constraint(equalToConstant: panelHeight)
        ])
    }
    
    private func setupScrollViewAndContent() {
        pdfScrollView = UIScrollView()
        pdfScrollView.translatesAutoresizingMaskIntoConstraints = false
        pdfScrollView.delegate = self
        // Задаем максимально допустимый зум
        pdfScrollView.maximumZoomScale = 4.0
        // Задаем минимальный зум по умолчанию (будет пересчитан в viewDidLayoutSubviews)
        pdfScrollView.minimumZoomScale = 1.0
        let savedZoom = UserDefaults.standard.float(forKey: zoomScaleKey)
        pdfScrollView.zoomScale = savedZoom > 0 ? CGFloat(savedZoom) : 1.0
        view.addSubview(pdfScrollView)
        
        NSLayoutConstraint.activate([
            pdfScrollView.topAnchor.constraint(equalTo: topPanel.bottomAnchor),
            pdfScrollView.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor),
            pdfScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        pdfContentView = UIView()
        pdfContentView.translatesAutoresizingMaskIntoConstraints = false
        pdfScrollView.addSubview(pdfContentView)
        
        if let pdfImage = renderPDFtoImage(url: pdfURL) {
            let pdfSize = pdfImage.size
            NSLayoutConstraint.activate([
                pdfContentView.topAnchor.constraint(equalTo: pdfScrollView.topAnchor),
                pdfContentView.bottomAnchor.constraint(equalTo: pdfScrollView.bottomAnchor),
                pdfContentView.leadingAnchor.constraint(equalTo: pdfScrollView.leadingAnchor),
                pdfContentView.trailingAnchor.constraint(equalTo: pdfScrollView.trailingAnchor),
                pdfContentView.widthAnchor.constraint(equalToConstant: pdfSize.width),
                pdfContentView.heightAnchor.constraint(equalToConstant: pdfSize.height)
            ])
        } else {
            NSLayoutConstraint.activate([
                pdfContentView.topAnchor.constraint(equalTo: pdfScrollView.topAnchor),
                pdfContentView.bottomAnchor.constraint(equalTo: pdfScrollView.bottomAnchor),
                pdfContentView.leadingAnchor.constraint(equalTo: pdfScrollView.leadingAnchor),
                pdfContentView.trailingAnchor.constraint(equalTo: pdfScrollView.trailingAnchor)
            ])
        }
    }
    
    private func setupPDFAndDrawingViews() {
        pdfImageView = UIImageView()
        pdfImageView.translatesAutoresizingMaskIntoConstraints = false
        pdfImageView.contentMode = .scaleAspectFit
        // Включаем взаимодействие, чтобы кнопки внутри работали
        pdfImageView.isUserInteractionEnabled = true
        if let pdfImage = renderPDFtoImage(url: pdfURL) {
            pdfImageView.image = pdfImage
        }
        pdfContentView.addSubview(pdfImageView)
        
        drawingView = DrawingView(frame: .zero)
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.backgroundColor = .clear
        drawingView.onLineDrawn = { [weak self] start, end in
            guard let self = self else { return }
            self.repository.saveLine(for: self.drawingId, start: start, end: end)
        }
        drawingView.isUserInteractionEnabled = false
        pdfContentView.addSubview(drawingView)
        
        NSLayoutConstraint.activate([
            pdfImageView.topAnchor.constraint(equalTo: pdfContentView.topAnchor),
            pdfImageView.bottomAnchor.constraint(equalTo: pdfContentView.bottomAnchor),
            pdfImageView.leadingAnchor.constraint(equalTo: pdfContentView.leadingAnchor),
            pdfImageView.trailingAnchor.constraint(equalTo: pdfContentView.trailingAnchor),
            
            drawingView.topAnchor.constraint(equalTo: pdfContentView.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: pdfContentView.bottomAnchor),
            drawingView.leadingAnchor.constraint(equalTo: pdfContentView.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: pdfContentView.trailingAnchor)
        ])
    }
    
    private func setupButtons() {
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
    }
    
    private func setupPhotoMarkerTapRecognizer() {
        photoMarkerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePhotoMarkerTap(_:)))
        photoMarkerTapRecognizer.isEnabled = false
        view.addGestureRecognizer(photoMarkerTapRecognizer)
    }
    
    private func loadSavedLines() {
        let savedLines = repository.loadLines(for: drawingId)
        let lineObjects = savedLines.map { Line(start: $0.0, end: $0.1) }
        drawingView.loadLines(lineObjects)
    }
    
    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return pdfContentView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        UserDefaults.standard.set(Float(scale), forKey: zoomScaleKey)
    }
    
    // MARK: - Режимы работы
    @objc private func toggleDrawingMode(_ sender: UIButton) {
        drawingEnabled.toggle()
        drawingView.isUserInteractionEnabled = drawingEnabled
        let imageName = drawingEnabled ? "Line_active" : "Line_passive"
        drawingToggleButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    @objc private func toggleTopButtonMode(_ sender: UIButton) {
        topButtonActive.toggle()
        let imageName = topButtonActive ? "Photo_active_1" : "Photo_passive_1"
        topToggleButton.setImage(UIImage(named: imageName), for: .normal)
        photoMarkerTapRecognizer.isEnabled = topButtonActive
    }
    
    // MARK: - Установка фото-маркера
    @objc private func handlePhotoMarkerTap(_ sender: UITapGestureRecognizer) {
        let locationInView = sender.location(in: pdfContentView)
        let markerSize: CGFloat = 30.0
        let markerFrame = CGRect(x: locationInView.x - markerSize/2,
                                 y: locationInView.y - markerSize/2,
                                 width: markerSize,
                                 height: markerSize)
        let markerButton = PhotoMarkerButton(frame: markerFrame)
        markerButton.backgroundColor = .red
        markerButton.layer.cornerRadius = markerSize / 2
        markerButton.clipsToBounds = true
        markerButton.addTarget(self, action: #selector(photoMarkerTapped(_:)), for: .touchUpInside)
        pdfImageView.addSubview(markerButton)
        pdfImageView.bringSubviewToFront(markerButton)
        
        let normalizedX = locationInView.x / pdfContentView.bounds.width
        let normalizedY = locationInView.y / pdfContentView.bounds.height
        markerButton.normalizedCoordinate = CGPoint(x: normalizedX, y: normalizedY)
        
        currentPhotoMarker = markerButton
        photoMarkerTapRecognizer.isEnabled = false
        presentCamera()
    }
    
    // MARK: - Работа с камерой
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
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
        
        let markerId = UUID()
        marker.photoEntityId = markerId
        let photoNumber = repository.getNextPhotoNumber(forDrawing: drawingId)
        
        repository.savePhotoMarker(forDrawing: drawingId,
                                   withId: markerId,
                                   image: image,
                                   photoNumber: photoNumber,
                                   timestamp: Date(),
                                   coordinateX: Double(normalized.x),
                                   coordinateY: Double(normalized.y))
        
        marker.photo = image
        marker.setBackgroundImage(image, for: .normal)
        
        currentPhotoMarker = nil
        photoMarkerTapRecognizer.isEnabled = topButtonActive
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        currentPhotoMarker?.removeFromSuperview()
        currentPhotoMarker = nil
        photoMarkerTapRecognizer.isEnabled = topButtonActive
    }
    
    // MARK: - Работа с фото-маркерами
    @objc private func photoMarkerTapped(_ sender: PhotoMarkerButton) {
        guard let photo = sender.photo else { return }
        presentPhoto(photo, forMarker: sender)
    }
    
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
    
    // MARK: - Загрузка фото-маркеров
    private func loadPhotoMarkers() {
        let markers = repository.loadPhotoMarkers(forDrawing: drawingId)
        let markerSize: CGFloat = 30.0
        
        pdfContentView.layoutIfNeeded()
        
        for markerData in markers {
            let markerButton = PhotoMarkerButton(frame: CGRect(x: 0, y: 0, width: markerSize, height: markerSize))
            markerButton.photo = markerData.image
            markerButton.setBackgroundImage(markerData.image, for: .normal)
            markerButton.backgroundColor = .red
            markerButton.layer.cornerRadius = markerSize / 2
            markerButton.clipsToBounds = true
            markerButton.addTarget(self, action: #selector(photoMarkerTapped(_:)), for: .touchUpInside)
            
            markerButton.photoEntityId = markerData.id
            markerButton.normalizedCoordinate = markerData.coordinate
            
            let centerX = markerData.coordinate.x * pdfContentView.bounds.width
            let centerY = markerData.coordinate.y * pdfContentView.bounds.height
            markerButton.center = CGPoint(x: centerX, y: centerY)
            
            pdfImageView.addSubview(markerButton)
            pdfImageView.bringSubviewToFront(markerButton)
        }
    }
    
    @objc private func deletePhotoMarkerAction(_ sender: UIButton) {
        guard let marker = currentViewingMarker, let markerId = marker.photoEntityId else { return }
        repository.deletePhotoMarker(withId: markerId)
        marker.removeFromSuperview()
        dismiss(animated: true)
    }
}
