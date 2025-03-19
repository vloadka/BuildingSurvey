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

struct PointMarkerData {
    let id: UUID
    let coordinate: CGPoint  // координаты хранятся в нормализованном виде (0...1)
}

struct PolylineData {
    let id: UUID
    let points: [CGPoint]
    let closed: Bool
}

struct TextMarkerData {
    let id: UUID
    let text: String
    let coordinate: CGPoint
}
struct LayerData {
    let id: UUID
    let name: String
    let color: UIColor
}

struct RectangleData {
    let id: UUID
    let rect: CGRect
}

class PDFViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    // Исходные свойства
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
    
    // Фото-режим
    private var topToggleButton: UIButton!
    private var topButtonActive: Bool = false
    private var photoMarkerTapRecognizer: UITapGestureRecognizer!
    private var currentPhotoMarker: PhotoMarkerButton?
    private var currentViewingMarker: PhotoMarkerButton?
    
    // Режим создания точек
    private var pointToggleButton: UIButton!
    private var pointCreationEnabled: Bool = false
    private var pointCreationTapRecognizer: UITapGestureRecognizer!
    
    // Режим создания полилиний
    private var polylineToggleButton: UIButton!
    private var polylineModeEnabled: Bool = false
    private var polylineTapRecognizer: UITapGestureRecognizer!
    private var currentPolylinePoints: [CGPoint] = []
    private var currentPolylineLayer: CAShapeLayer?
    private var polylineControlPanel: UIView?
    
    // Режим ввода текста
    private var textToggleButton: UIButton!
    private var textModeEnabled: Bool = false
    private var textTapRecognizer: UITapGestureRecognizer!
    
    // Режим создания четырехугольника
    private var rectangleToggleButton: UIButton!
    private var rectangleModeEnabled: Bool = false
    private var rectangleTapRecognizer: UITapGestureRecognizer!
    private var rectangleFirstPoint: CGPoint?
    private var rectangleLayer: CAShapeLayer?
    
    // Ключ для сохранения зума
    private var zoomScaleKey: String {
        return "pdfZoomScale_\(drawingId.uuidString)"
    }
    
    private let project: Project // или ProjectEntity, если вы работаете с сущностями Core Data
        
        init(pdfURL: URL, drawingId: UUID, repository: GeneralRepository, project: Project) {
            self.pdfURL = pdfURL
            self.drawingId = drawingId
            self.repository = repository
            self.project = project
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
        
        // Настройка распознавателей для создания точек, полилиний и текста
        pointCreationTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePointCreationTap(_:)))
        pointCreationTapRecognizer.isEnabled = false
        pdfContentView.addGestureRecognizer(pointCreationTapRecognizer)
        
        polylineTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePolylineTap(_:)))
        polylineTapRecognizer.isEnabled = false
        pdfContentView.addGestureRecognizer(polylineTapRecognizer)
        
        textTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTextTap(_:)))
        textTapRecognizer.isEnabled = false
        pdfContentView.addGestureRecognizer(textTapRecognizer)
        
        // Инициализация распознавателя для прямоугольника
            rectangleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleRectangleTap(_:)))
            rectangleTapRecognizer.isEnabled = false
            pdfContentView.addGestureRecognizer(rectangleTapRecognizer)
        
        loadSavedLines()
        // Загрузка фото-маркеров, точек, полилиний и текстовых меток происходит в viewDidLayoutSubviews, когда размеры установлены
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollSize = pdfScrollView.bounds.size
        let contentSize = pdfContentView.bounds.size
        if contentSize.width > 0 && contentSize.height > 0 {
            let widthScale = scrollSize.width / contentSize.width
            let heightScale = scrollSize.height / contentSize.height
            let minScale = min(widthScale, heightScale)
            pdfScrollView.minimumZoomScale = minScale
            
            // Задаём желаемый масштаб 60% (0.6),
            // если сохранённого значения нет.
            let defaultScale: CGFloat = 0.5
            let initialScale: CGFloat
            if let saved = UserDefaults.standard.value(forKey: zoomScaleKey) as? Float, saved > 0 {
                initialScale = CGFloat(saved)
            } else {
                // Если defaultScale меньше минимального, принудительно используем minScale.
                initialScale = defaultScale >= minScale ? defaultScale : minScale
            }
            pdfScrollView.zoomScale = initialScale
        }
        
        if bottomPanel.subviews.count > 0 && pdfContentView.bounds.size != .zero {
            loadPhotoMarkers()
            loadPointMarkers()
            loadPolylineMarkers()
            loadTextMarkers()
            loadRectangleMarkers()
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
        pdfScrollView.maximumZoomScale = 4.0
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
        
        // Кнопка для линий (рисование линий)
        drawingToggleButton = UIButton(type: .custom)
        drawingToggleButton.translatesAutoresizingMaskIntoConstraints = false
        drawingToggleButton.setImage(UIImage(named: "Line_passive"), for: .normal)
        drawingToggleButton.addTarget(self, action: #selector(toggleDrawingMode(_:)), for: .touchUpInside)
        bottomPanel.addSubview(drawingToggleButton)
        
        // Кнопка для полилиний
        polylineToggleButton = UIButton(type: .custom)
        polylineToggleButton.translatesAutoresizingMaskIntoConstraints = false
        polylineToggleButton.setImage(UIImage(named: "broken_line_passive"), for: .normal)
        polylineToggleButton.addTarget(self, action: #selector(togglePolylineMode(_:)), for: .touchUpInside)
        bottomPanel.addSubview(polylineToggleButton)
        
        // Кнопка для точек
        pointToggleButton = UIButton(type: .custom)
        pointToggleButton.translatesAutoresizingMaskIntoConstraints = false
        pointToggleButton.setImage(UIImage(named: "point_defect_passive"), for: .normal)
        pointToggleButton.addTarget(self, action: #selector(togglePointMode(_:)), for: .touchUpInside)
        bottomPanel.addSubview(pointToggleButton)
        
        // Кнопка для ввода текста
        textToggleButton = UIButton(type: .custom)
        textToggleButton.translatesAutoresizingMaskIntoConstraints = false
        textToggleButton.setImage(UIImage(named: "text_passive"), for: .normal)
        textToggleButton.addTarget(self, action: #selector(toggleTextMode(_:)), for: .touchUpInside)
        bottomPanel.addSubview(textToggleButton)
        
        rectangleToggleButton = UIButton(type: .custom)
        rectangleToggleButton.translatesAutoresizingMaskIntoConstraints = false
        rectangleToggleButton.setImage(UIImage(named: "rectangle_passive"), for: .normal)
        rectangleToggleButton.addTarget(self, action: #selector(toggleRectangleMode(_:)), for: .touchUpInside)
        bottomPanel.addSubview(rectangleToggleButton)
        
        // Кнопка для работы со слоями
          setupLayerButton()
        
        // Располагаем кнопки горизонтально: [text] - [polyline] - [drawing] - [point]
        NSLayoutConstraint.activate([
            
            layerButton.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 16),
                   layerButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
                   layerButton.widthAnchor.constraint(equalToConstant: 30),
                   layerButton.heightAnchor.constraint(equalToConstant: 30),
            
            drawingToggleButton.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            drawingToggleButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            drawingToggleButton.heightAnchor.constraint(equalToConstant: 44),
            drawingToggleButton.widthAnchor.constraint(equalToConstant: 44),
            
            polylineToggleButton.trailingAnchor.constraint(equalTo: drawingToggleButton.leadingAnchor, constant: -20),
            polylineToggleButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            polylineToggleButton.heightAnchor.constraint(equalToConstant: 44),
            polylineToggleButton.widthAnchor.constraint(equalToConstant: 44),
            
            pointToggleButton.leadingAnchor.constraint(equalTo: drawingToggleButton.trailingAnchor, constant: 20),
            pointToggleButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            pointToggleButton.heightAnchor.constraint(equalToConstant: 44),
            pointToggleButton.widthAnchor.constraint(equalToConstant: 44),
            
            textToggleButton.trailingAnchor.constraint(equalTo: polylineToggleButton.leadingAnchor, constant: -20),
            textToggleButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            textToggleButton.heightAnchor.constraint(equalToConstant: 44),
            textToggleButton.widthAnchor.constraint(equalToConstant: 44),
            
            rectangleToggleButton.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -16),
                rectangleToggleButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
                rectangleToggleButton.widthAnchor.constraint(equalToConstant: 44),
                rectangleToggleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Кнопки на верхней панели
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
    
    // Новый метод для загрузки полилиний
    private func loadPolylineMarkers() {
        let polylines = repository.loadPolylines(forDrawing: drawingId)
        for polyline in polylines {
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = UIColor.orange.cgColor
            shapeLayer.lineWidth = 2.0
            shapeLayer.fillColor = UIColor.clear.cgColor
            let path = UIBezierPath()
            if let first = polyline.points.first {
                path.move(to: first)
                for point in polyline.points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            shapeLayer.path = path.cgPath
            pdfContentView.layer.addSublayer(shapeLayer)
        }
    }
    
    // Новый метод для загрузки текстовых меток
    private func loadTextMarkers() {
        let texts = repository.loadTexts(forDrawing: drawingId)
        for textMarker in texts {
            let label = UILabel()
            label.text = textMarker.text
            label.textColor = .blue
            label.backgroundColor = .clear
            label.sizeToFit()
            let centerX = textMarker.coordinate.x * pdfContentView.bounds.width
            let centerY = textMarker.coordinate.y * pdfContentView.bounds.height
            label.center = CGPoint(x: centerX, y: centerY)
            pdfImageView.addSubview(label)
            pdfImageView.bringSubviewToFront(label)
        }
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
        
        @objc private func togglePointMode(_ sender: UIButton) {
            pointCreationEnabled.toggle()
            let imageName = pointCreationEnabled ? "point_defect_active" : "point_defect_passive"
            pointToggleButton.setImage(UIImage(named: imageName), for: .normal)
            pointCreationTapRecognizer.isEnabled = pointCreationEnabled
        }
        
        @objc private func togglePolylineMode(_ sender: UIButton) {
            polylineModeEnabled.toggle()
            let imageName = polylineModeEnabled ? "broken_line_active" : "broken_line_passive"
            polylineToggleButton.setImage(UIImage(named: imageName), for: .normal)
            polylineTapRecognizer.isEnabled = polylineModeEnabled
            
            // Если режим выключается, отменяем незавершённую полилинию
            if !polylineModeEnabled {
                cancelCurrentPolyline()
            }
        }
    
    @objc private func toggleTextMode(_ sender: UIButton) {
        textModeEnabled.toggle()
        let imageName = textModeEnabled ? "text_active" : "text_passive"
        textToggleButton.setImage(UIImage(named: imageName), for: .normal)
        textTapRecognizer.isEnabled = textModeEnabled
    }
    
    // MARK: - Обработка фото-маркеров
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
    
    // MARK: - Обработка создания точки
    @objc private func handlePointCreationTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: pdfContentView)
        let markerSize: CGFloat = 10.0
        let markerFrame = CGRect(x: location.x - markerSize/2,
                                 y: location.y - markerSize/2,
                                 width: markerSize,
                                 height: markerSize)
        let pointMarker = UIButton(frame: markerFrame)
        pointMarker.backgroundColor = .blue
        pointMarker.layer.cornerRadius = markerSize / 2
        pointMarker.clipsToBounds = true
        pdfImageView.addSubview(pointMarker)
        pdfImageView.bringSubviewToFront(pointMarker)
       
        let normalizedX = location.x / pdfContentView.bounds.width
        let normalizedY = location.y / pdfContentView.bounds.height
        let normalizedPoint = CGPoint(x: normalizedX, y: normalizedY)
       
        repository.savePoint(forDrawing: drawingId, coordinate: normalizedPoint)
    }
    
    // MARK: - Обработка создания полилинии
    @objc private func handlePolylineTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: pdfContentView)
        currentPolylinePoints.append(location)
        updatePolylineLayer()
        
        // При достижении 2 и более точек показываем панель управления полилинией
        if currentPolylinePoints.count == 2 {
            showPolylineControlPanel()
        }
    }
    
    private func updatePolylineLayer() {
        if currentPolylineLayer == nil {
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.green.cgColor
            layer.lineWidth = 2.0
            layer.fillColor = UIColor.clear.cgColor
            currentPolylineLayer = layer
            pdfContentView.layer.addSublayer(layer)
        }
        let path = UIBezierPath()
        if let first = currentPolylinePoints.first {
            path.move(to: first)
            for point in currentPolylinePoints.dropFirst() {
                path.addLine(to: point)
            }
        }
        currentPolylineLayer?.path = path.cgPath
    }
    
    private func showPolylineControlPanel() {
        // Скрываем все кнопки в нижней панели
        for subview in bottomPanel.subviews {
            subview.isHidden = true
        }
        
        polylineControlPanel = UIView()
        polylineControlPanel?.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.addSubview(polylineControlPanel!)
        
        NSLayoutConstraint.activate([
            polylineControlPanel!.topAnchor.constraint(equalTo: bottomPanel.topAnchor),
            polylineControlPanel!.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor),
            polylineControlPanel!.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
            polylineControlPanel!.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor)
        ])
        
        // Создаем 3 кнопки с изображениями: Отмена, Сохранение, Замыкание
        let cancelButton = UIButton(type: .custom)
        cancelButton.setImage(UIImage(named: "decline"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelPolylineAction), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        let saveButton = UIButton(type: .custom)
        saveButton.setImage(UIImage(named: "accept"), for: .normal)
        saveButton.addTarget(self, action: #selector(savePolylineAction), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "connect"), for: .normal)
        closeButton.addTarget(self, action: #selector(closePolylineAction), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        polylineControlPanel?.addSubview(cancelButton)
        polylineControlPanel?.addSubview(saveButton)
        polylineControlPanel?.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            // Размеры кнопок – 30x30
            cancelButton.widthAnchor.constraint(equalToConstant: 30),
            cancelButton.heightAnchor.constraint(equalToConstant: 30),
            saveButton.widthAnchor.constraint(equalToConstant: 30),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Размещение кнопок по центру панели
            cancelButton.centerYAnchor.constraint(equalTo: polylineControlPanel!.centerYAnchor),
            saveButton.centerYAnchor.constraint(equalTo: polylineControlPanel!.centerYAnchor),
            closeButton.centerYAnchor.constraint(equalTo: polylineControlPanel!.centerYAnchor),
            
            cancelButton.leadingAnchor.constraint(equalTo: polylineControlPanel!.leadingAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: polylineControlPanel!.trailingAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: polylineControlPanel!.centerXAnchor)
        ])
    }
    
    private func hidePolylineControlPanel() {
        polylineControlPanel?.removeFromSuperview()
        polylineControlPanel = nil
        // Восстанавливаем видимость исходных кнопок нижней панели
        for subview in bottomPanel.subviews {
            subview.isHidden = false
        }
    }
    
    // Отключаем режим полилиний – кнопка становится неактивной
    private func disablePolylineMode() {
        polylineModeEnabled = false
        polylineToggleButton.setImage(UIImage(named: "broken_line_passive"), for: .normal)
        polylineTapRecognizer.isEnabled = false
    }
    
    @objc private func cancelPolylineAction() {
        cancelCurrentPolyline()
        hidePolylineControlPanel()
        disablePolylineMode()
    }
    
    private func cancelCurrentPolyline() {
        currentPolylineLayer?.removeFromSuperlayer()
        currentPolylineLayer = nil
        currentPolylinePoints.removeAll()
    }
    
    @objc private func savePolylineAction() {
        // Сохраняем полилинию в открытом виде (без замыкания)
        repository.savePolyline(forDrawing: drawingId, points: currentPolylinePoints, closed: false)
        cancelCurrentPolyline()
        hidePolylineControlPanel()
        disablePolylineMode()
        loadPolylineMarkers() // Сразу показываем сохранённую полилинию
    }
    
    @objc private func closePolylineAction() {
        // Добавляем соединение между первой и последней точкой (замыкание)
        if let first = currentPolylinePoints.first {
            currentPolylinePoints.append(first)
            updatePolylineLayer()
        }
        repository.savePolyline(forDrawing: drawingId, points: currentPolylinePoints, closed: true)
        cancelCurrentPolyline()
        hidePolylineControlPanel()
        disablePolylineMode()
        loadPolylineMarkers() // Сразу показываем сохранённую полилинию
    }
    
    // MARK: - Обработка ввода текста
    @objc private func handleTextTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: pdfContentView)
        // Показываем alert с текстовым полем для ввода
        let alert = UIAlertController(title: "Введите текст", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Ваш текст"
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: { [weak self] _ in
            guard let self = self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            // Создаем метку с введенным текстом
            let label = UILabel()
            label.text = text
            label.textColor = .blue
            label.backgroundColor = .clear
            label.sizeToFit()
            label.center = location
            self.pdfImageView.addSubview(label)
            self.pdfImageView.bringSubviewToFront(label)
            
            // Сохраняем координаты текста в нормализованном виде
            let normalizedX = location.x / self.pdfContentView.bounds.width
            let normalizedY = location.y / self.pdfContentView.bounds.height
            let normalizedPoint = CGPoint(x: normalizedX, y: normalizedY)
            self.repository.saveText(forDrawing: self.drawingId, text: text, coordinate: normalizedPoint)
        }))
        present(alert, animated: true, completion: nil)
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
        
        // Кнопка закрытия
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissPhotoVC), for: .touchUpInside)
        photoVC.view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor, constant: -16)
        ])
        
        // Добавляем кнопку удаления фото-маркера
        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .red
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deletePhotoMarkerAction(_:)), for: .touchUpInside)
        photoVC.view.addSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.bottomAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            deleteButton.centerXAnchor.constraint(equalTo: photoVC.view.centerXAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30)
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
              let page = pdfDocument.page(at: 1) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let renderSize = pageRect.size
        let renderer = UIGraphicsImageRenderer(size: renderSize)
        let img = renderer.image { ctx in
            let context = ctx.cgContext
            context.saveGState()
            
            // Переворачиваем контекст, чтобы PDF не был вверх ногами
            context.translateBy(x: 0, y: renderSize.height)
            context.scaleBy(x: 1, y: -1)
            
            // Получаем трансформацию для корректного отображения страницы
            let transform = page.getDrawingTransform(.mediaBox, rect: CGRect(origin: .zero, size: renderSize), rotate: 0, preserveAspectRatio: true)
            context.concatenate(transform)
            
            context.drawPDFPage(page)
            context.restoreGState()
        }
        return img
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
    
    // MARK: - Загрузка точек
    private func loadPointMarkers() {
        let points = repository.loadPoints(forDrawing: drawingId)
        let markerSize: CGFloat = 10.0
        
        for pointData in points {
            let marker = UIButton(frame: CGRect(x: 0, y: 0, width: markerSize, height: markerSize))
            marker.backgroundColor = .blue
            marker.layer.cornerRadius = markerSize / 2
            marker.clipsToBounds = true
            
            let centerX = pointData.coordinate.x * pdfContentView.bounds.width
            let centerY = pointData.coordinate.y * pdfContentView.bounds.height
            marker.center = CGPoint(x: centerX, y: centerY)
            
            pdfImageView.addSubview(marker)
            pdfImageView.bringSubviewToFront(marker)
        }
    }
    
    // MARK: - Загрузка текстовых меток
    
    @objc private func deletePhotoMarkerAction(_ sender: UIButton) {
        guard let marker = currentViewingMarker, let markerId = marker.photoEntityId else { return }
        repository.deletePhotoMarker(withId: markerId)
        marker.removeFromSuperview()
        dismiss(animated: true)
    }
    
    
    private var layerButton: UIButton! {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.layerButton) as? UIButton }
        set { objc_setAssociatedObject(self, &AssociatedKeys.layerButton, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var layerDropdownView: UIView? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.layerDropdownView) as? UIView }
        set { objc_setAssociatedObject(self, &AssociatedKeys.layerDropdownView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var activeLayer: LayerData? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.activeLayer) as? LayerData }
        set { objc_setAssociatedObject(self, &AssociatedKeys.activeLayer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var layers: [LayerData] {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.layers) as? [LayerData] ?? [] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.layers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    
    private struct AssociatedKeys {
        static var layerButton: UInt8 = 0
        static var layerDropdownView: UInt8 = 0
        static var activeLayer: UInt8 = 0
        static var layers: UInt8 = 0
    }
    
    // Вызываем этот метод в viewDidLoad()
    func setupLayerButton() {
        layerButton = UIButton(type: .custom)
        layerButton.translatesAutoresizingMaskIntoConstraints = false
        // Убираем установку изображения и настраиваем кнопку как круг
        layerButton.layer.cornerRadius = 15 // половина от 30 (ширина/высота)
        layerButton.layer.borderWidth = 1.0
        layerButton.layer.borderColor = UIColor.gray.cgColor
        // Устанавливаем начальный цвет (если activeLayer не выбран, то можно задать дефолт, например, черный)
        layerButton.backgroundColor = activeLayer?.color ?? .black
        layerButton.addTarget(self, action: #selector(toggleLayerDropdown), for: .touchUpInside)
        bottomPanel.addSubview(layerButton)
        
        NSLayoutConstraint.activate([
            layerButton.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 16),
            layerButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            layerButton.widthAnchor.constraint(equalToConstant: 30),
            layerButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    
    @objc private func toggleLayerDropdown() {
        if layerDropdownView == nil {
            showLayerDropdown()
        } else {
            hideLayerDropdown()
        }
    }
    
    private func showLayerDropdown() {
        // Получаем слои (LayerEntity) из репозитория
        let layerEntities = repository.loadLayers(forProject: project)
        // Преобразуем LayerEntity в LayerData
        layers = layerEntities.map { entity in
            LayerData(
                id: entity.id ?? UUID(),
                name: entity.name ?? "",
                color: entity.uiColor ?? .black
            )
        }
        
        // Если слой с названием "0" отсутствует, добавляем его по умолчанию
        if !layers.contains(where: { $0.name == "0" }) {
            let defaultLayer = LayerData(id: UUID(), name: "0", color: .black)
            layers.insert(defaultLayer, at: 0)
            repository.saveLayer(forProject: project, layer: defaultLayer)
        }
        
        let dropdown = UIView()
        dropdown.translatesAutoresizingMaskIntoConstraints = false
        dropdown.backgroundColor = UIColor.white
        dropdown.layer.borderWidth = 1.0
        dropdown.layer.borderColor = UIColor.gray.cgColor
        dropdown.layer.cornerRadius = 5.0
        view.addSubview(dropdown)
        self.layerDropdownView = dropdown
        
        // Расположим dropdown чуть выше нижней панели
        NSLayoutConstraint.activate([
            dropdown.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 16),
            dropdown.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -16),
            dropdown.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: -8)
        ])
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        dropdown.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: dropdown.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: dropdown.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: dropdown.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: dropdown.trailingAnchor, constant: -8)
        ])
        
        // Для каждого слоя создаём ячейку
        for (index, layer) in layers.enumerated() {
            let layerCell = createLayerCell(for: layer)
            layerCell.tag = index // Используем tag для идентификации ячейки
            let tap = UITapGestureRecognizer(target: self, action: #selector(layerCellTapped(_:)))
            layerCell.addGestureRecognizer(tap)
            stackView.addArrangedSubview(layerCell)
        }
        
        // Добавляем кнопку "Добавить слой"
        let addLayerButton = UIButton(type: .system)
        addLayerButton.setTitle("Добавить слой", for: .normal)
        addLayerButton.addTarget(self, action: #selector(addLayerButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(addLayerButton)
    }

    
    private func hideLayerDropdown() {
        layerDropdownView?.removeFromSuperview()
        layerDropdownView = nil
    }
    
    private func createLayerCell(for layer: LayerData) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Если этот слой является активным, подсвечиваем его фон
        if let active = activeLayer, active.id == layer.id {
            container.backgroundColor = UIColor.systemGray5
        } else {
            container.backgroundColor = UIColor.white
        }
        
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        // Название слоя
        let nameLabel = UILabel()
        nameLabel.text = layer.name
        hStack.addArrangedSubview(nameLabel)

        // Спейсер
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])

        // Круг с цветом слоя
        let colorView = UIView()
        colorView.backgroundColor = layer.color
        colorView.layer.cornerRadius = 10
        colorView.clipsToBounds = true
        colorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorView.widthAnchor.constraint(equalToConstant: 20),
            colorView.heightAnchor.constraint(equalToConstant: 20)
        ])
        hStack.addArrangedSubview(colorView)
        
        // Кнопка удаления
        let deleteButton = UIButton(type: .custom)
        deleteButton.setImage(UIImage(named: "decline"), for: .normal)
        deleteButton.accessibilityIdentifier = layer.id.uuidString
        deleteButton.addTarget(self, action: #selector(deleteLayerButtonTapped(_:)), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: 20),
            deleteButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        hStack.addArrangedSubview(deleteButton)
        
        return container
    }


    
    @objc private func layerCellTapped(_ gesture: UITapGestureRecognizer) {
        if let cell = gesture.view {
            let index = cell.tag
            if index < layers.count {
                let selected = layers[index]
                activeLayer = selected
                // Обновляем внешний вид кнопки, устанавливая цвет выбранного слоя
                layerButton.backgroundColor = selected.color
                hideLayerDropdown()
            }
        }
    }
    
    private func saveNewLayer(from alert: UIAlertController, withColor color: UIColor) {
        guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
        let newLayer = LayerData(id: UUID(), name: name, color: color)
        repository.saveLayer(forProject: project, layer: newLayer)
        // Обновляем список слоев
        hideLayerDropdown()
        showLayerDropdown()
    }
    
    @objc private func deleteLayerButtonTapped(_ sender: UIButton) {
        guard let idString = sender.accessibilityIdentifier, let id = UUID(uuidString: idString) else { return }
        repository.deleteLayer(withId: id)
        hideLayerDropdown()
        showLayerDropdown()
    }
    
    @objc private func addLayerButtonTapped() {
        let addLayerVC = AddLayerViewController()
        addLayerVC.modalPresentationStyle = .formSheet
        addLayerVC.completion = { [weak self] name, color in
             guard let self = self else { return }
             let newLayer = LayerData(id: UUID(), name: name, color: color)
             self.repository.saveLayer(forProject: self.project, layer: newLayer)
             self.hideLayerDropdown()
             self.showLayerDropdown()
        }
        present(addLayerVC, animated: true, completion: nil)
    }
    
    // Метод для переключения режима рисования прямоугольника:
    @objc private func toggleRectangleMode(_ sender: UIButton) {
        rectangleModeEnabled.toggle()
        let imageName = rectangleModeEnabled ? "rectangle_active" : "rectangle_passive"
        rectangleToggleButton.setImage(UIImage(named: imageName), for: .normal)
        rectangleTapRecognizer.isEnabled = rectangleModeEnabled
        if !rectangleModeEnabled {
            rectangleFirstPoint = nil
            rectangleLayer?.removeFromSuperlayer()
            rectangleLayer = nil
        }
    }
    
    // Обработчик нажатий для рисования прямоугольника:
    @objc private func handleRectangleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: pdfContentView)
        if rectangleFirstPoint == nil {
            // Сохраняем первую точку как верхний левый угол
            rectangleFirstPoint = location
            // (опционально: можно отобразить небольшой маркер, чтобы показать первую точку)
        } else {
            guard let first = rectangleFirstPoint else { return }
            // Определяем координаты так, чтобы первая точка была верхним левым углом, а вторая – нижним правым
            let x = min(first.x, location.x)
            let y = min(first.y, location.y)
            let width = abs(first.x - location.x)
            let height = abs(first.y - location.y)
            let rect = CGRect(x: x, y: y, width: width, height: height)
            
            // Удаляем предыдущий прямоугольник (если был)
            rectangleLayer?.removeFromSuperlayer()
            
            // Рисуем прямоугольник
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.red.cgColor   // рамка красного цвета, можно изменить
            layer.lineWidth = 2.0
            layer.fillColor = UIColor.clear.cgColor     // прозрачное заполнение
            let path = UIBezierPath(rect: rect)
            layer.path = path.cgPath
            pdfContentView.layer.addSublayer(layer)
            rectangleLayer = layer
            
            // Сохраняем прямоугольник в базу данных
            repository.saveRectangle(forDrawing: drawingId, rect: rect)
            
            // Сбрасываем состояние
            rectangleFirstPoint = nil
            rectangleModeEnabled = false
            rectangleToggleButton.setImage(UIImage(named: "rectangle_passive"), for: .normal)
            rectangleTapRecognizer.isEnabled = false
        }
    }
    
    private func loadRectangleMarkers() {
        let rectangles = repository.loadRectangles(forDrawing: drawingId)
        for rect in rectangles {
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = UIColor.red.cgColor  // цвет рамки можно изменить
            shapeLayer.lineWidth = 2.0
            shapeLayer.fillColor = UIColor.clear.cgColor
            let path = UIBezierPath(rect: rect)
            shapeLayer.path = path.cgPath
            pdfContentView.layer.addSublayer(shapeLayer)
        }
    }
}
