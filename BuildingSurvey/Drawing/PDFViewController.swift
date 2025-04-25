//
//  PDFViewController.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 05.03.2025.
//

import UIKit
import CoreGraphics
import AVFAudio
import CoreData

// Класс для маркера с фотографией
class PhotoMarkerButton: UIButton {
    var photo: UIImage? {
        didSet {
            self.setImage(photo, for: .normal)
            self.imageView?.contentMode = .scaleAspectFill
        }
    }
    var photoEntityId: UUID?
    var normalizedCoordinate: CGPoint?  // Свойство для фиксированных координат

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.layer.cornerRadius = frame.size.width / 2
        self.imageView?.contentMode = .scaleAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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
    let color: UIColor
}

struct LineData {
    let id: UUID
    let start: CGPoint
    let end: CGPoint
    let color: UIColor
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
    let color: UIColor
}

struct TextData {
    let id: UUID
    let text: String
    let coordinate: CGPoint
    let color: UIColor
}

struct PointData {
    let id: UUID
    let coordinate: CGPoint
    let color: UIColor
}

struct AudioData {
    let id: UUID
    let audioData: Data
    let timestamp: Date
}

class PDFViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, AVAudioRecorderDelegate {
    private let scale: Double
    private let initialScale: CGFloat
    private var zoomInitialized = false
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
    
    // Объявляем свойства для функционала ластика
    private var eraserToggleButton: UIButton!
    private var eraserModeEnabled: Bool = false
    private var eraserTapRecognizer: UITapGestureRecognizer!
    
    private var currentPolylineId: UUID?
    
    // Объявляем переменную для кнопки аудио-записи
    var audioRecordingButton: UIButton!
    // Объявляем переменную для отслеживания состояния записи аудио
    var isAudioRecordingActive = false
    var audioRecorder: AVAudioRecorder?
    var recordingStatusLabel: UILabel?
    var currentRetakePhotoId: UUID?
    
    private var linesLoaded = false

    
    // Ключ для сохранения зума
    private var zoomScaleKey: String {
        return "pdfZoomScale_\(drawingId.uuidString)"
    }
    
    private let project: Project // или ProjectEntity, если вы работаете с сущностями Core Data
        
        init(pdfURL: URL, drawingId: UUID, repository: GeneralRepository, project: Project, scale: Double) {
            self.pdfURL = pdfURL
            self.drawingId = drawingId
            self.repository = repository
            self.project = project
            self.scale = scale
            self.initialScale = CGFloat(scale)
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
        
        // Инициализация распознавателя для режима ластика
        eraserTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleEraserTap(_:)))
        eraserTapRecognizer.isEnabled = false
        pdfContentView.addGestureRecognizer(eraserTapRecognizer)
        
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
        
        rectangleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleRectangleTap(_:)))
        rectangleTapRecognizer.isEnabled = false
        pdfContentView.addGestureRecognizer(rectangleTapRecognizer)
        
        // Модифицированное замыкание для обработки рисования линии:
        drawingView.onLineDrawn = { [weak self] start, end in
            guard let self = self else { return }
            // Генерируем уникальный идентификатор для линии
            let lineId = UUID()
            print("Line - start = \(start), end = \(end)")
            // Сохраняем линию с внешним идентификатором
            self.repository.saveLine(forDrawing: self.drawingId, lineId: lineId, start: start, end: end, layer: self.activeLayer)
            
            // Создаем CAShapeLayer для отображения линии
            let lineLayer = CAShapeLayer()
            lineLayer.strokeColor = self.activeLayer?.color.cgColor ?? UIColor.black.cgColor
            lineLayer.lineWidth = 2.0
            lineLayer.fillColor = UIColor.clear.cgColor
            
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            lineLayer.path = path.cgPath
            
            // Привязываем идентификатор к слою для дальнейшего удаления ластиком
            lineLayer.setValue(lineId.uuidString, forKey: "entityId")
            self.pdfContentView.layer.addSublayer(lineLayer)
        }
        
        // Загрузка сохранённых линий, которые уже добавлены в слой
//        loadSavedLines()
        
        // Загрузка фото-маркеров, точек, полилиний и текстовых меток происходит в viewDidLayoutSubviews, когда установлены размеры
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let scrollSize = pdfScrollView.bounds.size
        let contentSize = pdfContentView.bounds.size

        if contentSize.width > 0 && contentSize.height > 0 {
           let widthScale = scrollSize.width / contentSize.width
           let heightScale = scrollSize.height / contentSize.height
           let minScale = min(widthScale, heightScale)

           let extraZoomOutFactor: CGFloat = 0.01
           pdfScrollView.minimumZoomScale = minScale * extraZoomOutFactor
           pdfScrollView.maximumZoomScale = 10.0

           if !zoomInitialized {
               let clamped = max(pdfScrollView.minimumZoomScale,
                                 min(initialScale, pdfScrollView.maximumZoomScale))
               pdfScrollView.setZoomScale(clamped, animated: false)
               zoomInitialized = true
           }
       }
        
        // ── ЗАГРУЗКА ЛИНИЙ ПОСЛЕ ЛЭЙАУТА ──
        if !linesLoaded && pdfContentView.bounds.size != .zero {
            print("🗒 loadSavedLines(): bounds = \(pdfContentView.bounds.size)")
            loadSavedLines()
            linesLoaded = true
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
            
            // Создаём верхнюю и нижнюю панели
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
            
            // Добавляем кнопку настроек на верхнюю панель
            let topIconButton = UIButton(type: .custom)
            topIconButton.translatesAutoresizingMaskIntoConstraints = false
            topIconButton.setImage(UIImage(named: "settings"), for: .normal)
            topPanel.addSubview(topIconButton)
            
            // Добавляем кнопку фото-маркера на верхнюю панель
            topToggleButton = UIButton(type: .custom)
            topToggleButton.translatesAutoresizingMaskIntoConstraints = false
            topToggleButton.setImage(UIImage(named: "Photo_passive_1"), for: .normal)
            topToggleButton.addTarget(self, action: #selector(toggleTopButtonMode(_:)), for: .touchUpInside)
            topPanel.addSubview(topToggleButton)
            
            // Добавляем кнопку аудио-записи на верхнюю панель
            audioRecordingButton = UIButton(type: .custom)
            audioRecordingButton.translatesAutoresizingMaskIntoConstraints = false
            audioRecordingButton.setImage(UIImage(named: "audio_start"), for: .normal)
            audioRecordingButton.addTarget(self, action: #selector(toggleAudioRecording(_:)), for: .touchUpInside)
            topPanel.addSubview(audioRecordingButton)
            
            // Устанавливаем констрейнты для кнопок на верхней панели
            NSLayoutConstraint.activate([
                // Кнопка настроек слева
                topIconButton.leadingAnchor.constraint(equalTo: topPanel.leadingAnchor, constant: 16),
                topIconButton.centerYAnchor.constraint(equalTo: topPanel.centerYAnchor),
                topIconButton.heightAnchor.constraint(equalToConstant: 30),
                topIconButton.widthAnchor.constraint(equalToConstant: 30),
                
                // Кнопка фото-маркера справа
                topToggleButton.trailingAnchor.constraint(equalTo: topPanel.trailingAnchor, constant: -16),
                topToggleButton.centerYAnchor.constraint(equalTo: topPanel.centerYAnchor),
                topToggleButton.heightAnchor.constraint(equalToConstant: 30),
                topToggleButton.widthAnchor.constraint(equalToConstant: 30),
                
                // Кнопка аудио-записи располагается между ними
                audioRecordingButton.trailingAnchor.constraint(equalTo: topToggleButton.leadingAnchor, constant: -16),
                audioRecordingButton.centerYAnchor.constraint(equalTo: topPanel.centerYAnchor),
                audioRecordingButton.widthAnchor.constraint(equalToConstant: 30),
                audioRecordingButton.heightAnchor.constraint(equalToConstant: 30)
            ])
    }
    
    private func setupScrollViewAndContent() {
        pdfScrollView = UIScrollView()
        pdfScrollView.translatesAutoresizingMaskIntoConstraints = false
        pdfScrollView.delegate = self
        pdfScrollView.maximumZoomScale = 10.0
        pdfScrollView.minimumZoomScale = 0.01
        let savedZoom = UserDefaults.standard.float(forKey: zoomScaleKey)
        pdfScrollView.zoomScale = savedZoom > 0 ? CGFloat(savedZoom) : initialScale
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
        // Замыкание, которое вызывается после рисования линии
        drawingView.onLineDrawn = { [weak self] start, end in
            guard let self = self else { return }
            // Генерируем уникальный идентификатор для линии
            let lineId = UUID()
            // Сохраняем линию с новым идентификатором
            self.repository.saveLine(forDrawing: self.drawingId,
                                     lineId: lineId,
                                     start: start,
                                     end: end,
                                     layer: self.activeLayer)
            
            // Создаем CAShapeLayer для отображения линии сразу после рисования
            let lineLayer = CAShapeLayer()
            lineLayer.strokeColor = self.activeLayer?.color.cgColor ?? UIColor.black.cgColor
            lineLayer.lineWidth = 2.0
            lineLayer.fillColor = UIColor.clear.cgColor
            
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            lineLayer.path = path.cgPath
            
            // Привязываем уникальный идентификатор и тип ("line") для возможности удаления ластиком
            lineLayer.setValue(lineId.uuidString, forKey: "entityId")
            lineLayer.setValue("line", forKey: "entityType")
            
            self.pdfContentView.layer.addSublayer(lineLayer)
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
        // Кнопка для работы со слоями
            setupLayerButton()
        
        // Создаем остальные кнопки
        textToggleButton = UIButton(type: .custom)
        textToggleButton.translatesAutoresizingMaskIntoConstraints = false
        textToggleButton.setImage(UIImage(named: "text_passive"), for: .normal)
        textToggleButton.addTarget(self, action: #selector(toggleTextMode(_:)), for: .touchUpInside)
        
        polylineToggleButton = UIButton(type: .custom)
        polylineToggleButton.translatesAutoresizingMaskIntoConstraints = false
        polylineToggleButton.setImage(UIImage(named: "broken_line_passive"), for: .normal)
        polylineToggleButton.addTarget(self, action: #selector(togglePolylineMode(_:)), for: .touchUpInside)
        
        drawingToggleButton = UIButton(type: .custom)
        drawingToggleButton.translatesAutoresizingMaskIntoConstraints = false
        drawingToggleButton.setImage(UIImage(named: "Line_passive"), for: .normal)
        drawingToggleButton.addTarget(self, action: #selector(toggleDrawingMode(_:)), for: .touchUpInside)
        
        pointToggleButton = UIButton(type: .custom)
        pointToggleButton.translatesAutoresizingMaskIntoConstraints = false
        pointToggleButton.setImage(UIImage(named: "point_defect_passive"), for: .normal)
        pointToggleButton.addTarget(self, action: #selector(togglePointMode(_:)), for: .touchUpInside)
        
        eraserToggleButton = UIButton(type: .custom)
        eraserToggleButton.translatesAutoresizingMaskIntoConstraints = false
        eraserToggleButton.setImage(UIImage(named: "eraser_passive"), for: .normal)
        eraserToggleButton.addTarget(self, action: #selector(toggleEraserMode(_:)), for: .touchUpInside)
        
        rectangleToggleButton = UIButton(type: .custom)
        rectangleToggleButton.translatesAutoresizingMaskIntoConstraints = false
        rectangleToggleButton.setImage(UIImage(named: "rectangle_passive"), for: .normal)
        rectangleToggleButton.addTarget(self, action: #selector(toggleRectangleMode(_:)), for: .touchUpInside)
        
        // Создаем StackView, включающий все кнопки нижней панели в нужном порядке
        // Порядок: [layerButton, textToggleButton, polylineToggleButton, drawingToggleButton, pointToggleButton, eraserToggleButton, rectangleToggleButton]
        let buttonStack = UIStackView(arrangedSubviews: [
            layerButton,
            textToggleButton,
            polylineToggleButton,
            drawingToggleButton,
            pointToggleButton,
            eraserToggleButton,
            rectangleToggleButton
        ])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.distribution = .equalSpacing
        buttonStack.spacing = 10  // Опционально можно задать фиксированный промежуток
        
        // Добавляем StackView на нижнюю панель
        bottomPanel.addSubview(buttonStack)
        
        // Привязываем StackView к краям нижней панели
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -16),
            buttonStack.topAnchor.constraint(equalTo: bottomPanel.topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor)
        ])
        
        // Устанавливаем для кнопок фиксированные размеры:
            // layerButton получит размер 30x30, остальные кнопки — 44x44
            for view in buttonStack.arrangedSubviews {
                if view == layerButton {
                    view.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    view.heightAnchor.constraint(equalToConstant: 30).isActive = true
                } else {
                    view.widthAnchor.constraint(equalToConstant: 44).isActive = true
                    view.heightAnchor.constraint(equalToConstant: 44).isActive = true
                }
            }
        
        // Настройка верхней панели (например, кнопки настроек и фото-маркера)
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
        
        if let firstLine = savedLines.first {
            drawingView.currentLineColor = firstLine.color
        }
        
        for lineData in savedLines {
            let lineLayer = CAShapeLayer()
            lineLayer.strokeColor = lineData.color.cgColor
            lineLayer.lineWidth = 2.0
            lineLayer.fillColor = UIColor.clear.cgColor
            let absStart = lineData.start
            let absEnd   = lineData.end
            print("id линии \(lineData.id):")
            print("LoadLine - start = \(absStart), end = \(absEnd)")
            
            let path = UIBezierPath()
            path.move(to: absStart)
            path.addLine(to: absEnd)
            lineLayer.path = path.cgPath
            
            // Устанавливаем идентификатор линии для возможности удаления ластиком
            lineLayer.setValue(lineData.id.uuidString, forKey: "entityId")
            
            pdfContentView.layer.addSublayer(lineLayer)
        }
    }
    
    // Новый метод для загрузки полилиний
    private func loadPolylineMarkers() {
        let polylineDataArray = repository.loadPolylines(forDrawing: drawingId)  // [PolylineData]
        for polylineData in polylineDataArray {
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = polylineData.color.cgColor
            shapeLayer.lineWidth = 2.0
            shapeLayer.fillColor = UIColor.clear.cgColor
            print("LoadPolyLine = \(polylineData.points)")
            let path = UIBezierPath()
            if let first = polylineData.points.first {
                path.move(to: first)
                for point in polylineData.points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            shapeLayer.path = path.cgPath
            // Добавляем массив точек в слой, чтобы ластик мог корректно вычислить расстояние до полилинии
            shapeLayer.setValue(polylineData.points, forKey: "points")
            // Присваиваем уникальный идентификатор и тип "polyline" для корректного удаления
            shapeLayer.setValue(polylineData.id.uuidString, forKey: "entityId")
            shapeLayer.setValue("polyline", forKey: "entityType")
            
            pdfContentView.layer.addSublayer(shapeLayer)
        }
    }

    // Метод для загрузки текстовых меток
    private func loadTextMarkers() {
        // Удаляем все существующие текстовые метки (UILabel), добавленные ранее
        pdfImageView.subviews.forEach { subview in
            if let label = subview as? UILabel, label.accessibilityIdentifier != nil {
                label.removeFromSuperview()
            }
        }
        
        let texts = repository.loadTexts(forDrawing: drawingId)  // [TextData]
        for textData in texts {
            let label = UILabel()
            label.text = textData.text
            label.textColor = textData.color
            label.backgroundColor = .clear
            label.sizeToFit()
            print("LoadText = \(textData.coordinate)")
            label.center = textData.coordinate
            // Устанавливаем уникальный идентификатор для метки
            label.accessibilityIdentifier = textData.id.uuidString
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
        if !drawingEnabled {
            // Включаем режим линий и блокируем остальные кнопки
            drawingEnabled = true
            drawingView.isUserInteractionEnabled = true
            drawingToggleButton.setImage(UIImage(named: "Line_active"), for: .normal)
            disableAllCreationButtons(except: drawingToggleButton)
            
            // Если какой-либо другой режим был активен, убедитесь, что он выключен
            polylineModeEnabled = false
            pointCreationEnabled = false
            textModeEnabled = false
            rectangleModeEnabled = false
        } else {
            // Выключаем режим линий и разблокируем остальные кнопки
            drawingEnabled = false
            drawingView.isUserInteractionEnabled = false
            drawingToggleButton.setImage(UIImage(named: "Line_passive"), for: .normal)
            enableAllCreationButtons()
        }
    }
        
    @objc private func toggleTopButtonMode(_ sender: UIButton) {
        if !topButtonActive {
            topButtonActive = true
            let imageName = "Photo_active_1"
            topToggleButton.setImage(UIImage(named: imageName), for: .normal)
            photoMarkerTapRecognizer.isEnabled = true
            // Блокируем остальные кнопки, кроме кнопки фото-маркера
            disableAllCreationButtons(except: topToggleButton)
        } else {
            topButtonActive = false
            let imageName = "Photo_passive_1"
            topToggleButton.setImage(UIImage(named: imageName), for: .normal)
            photoMarkerTapRecognizer.isEnabled = false
            // Разблокируем все кнопки
            enableAllCreationButtons()
        }
    }
        
    @objc private func togglePointMode(_ sender: UIButton) {
        if !pointCreationEnabled {
            pointCreationEnabled = true
            pointToggleButton.setImage(UIImage(named: "point_defect_active"), for: .normal)
            pointCreationTapRecognizer.isEnabled = true
            disableAllCreationButtons(except: pointToggleButton)
            
            drawingEnabled = false
            polylineModeEnabled = false
            textModeEnabled = false
            rectangleModeEnabled = false
        } else {
            pointCreationEnabled = false
            pointToggleButton.setImage(UIImage(named: "point_defect_passive"), for: .normal)
            pointCreationTapRecognizer.isEnabled = false
            enableAllCreationButtons()
        }
    }
        
    @objc private func togglePolylineMode(_ sender: UIButton) {
        if !polylineModeEnabled {
            polylineModeEnabled = true
            polylineToggleButton.setImage(UIImage(named: "broken_line_active"), for: .normal)
            polylineTapRecognizer.isEnabled = true
            disableAllCreationButtons(except: polylineToggleButton)
            
            drawingEnabled = false
            pointCreationEnabled = false
            textModeEnabled = false
            rectangleModeEnabled = false
        } else {
            polylineModeEnabled = false
            polylineToggleButton.setImage(UIImage(named: "broken_line_passive"), for: .normal)
            polylineTapRecognizer.isEnabled = false
            enableAllCreationButtons()
            cancelCurrentPolyline() // если нужно отменить незавершённую полилинию
        }
    }
    
    @objc private func toggleTextMode(_ sender: UIButton) {
        if !textModeEnabled {
            textModeEnabled = true
            textToggleButton.setImage(UIImage(named: "text_active"), for: .normal)
            textTapRecognizer.isEnabled = true
            disableAllCreationButtons(except: textToggleButton)
            
            drawingEnabled = false
            polylineModeEnabled = false
            pointCreationEnabled = false
            rectangleModeEnabled = false
        } else {
            textModeEnabled = false
            textToggleButton.setImage(UIImage(named: "text_passive"), for: .normal)
            textTapRecognizer.isEnabled = false
            enableAllCreationButtons()
        }
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
        
        markerButton.normalizedCoordinate = locationInView
        
        // если идентификатор ещё не задан, генерируем его
            if markerButton.photoEntityId == nil {
                 markerButton.photoEntityId = UUID()
            }
        
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
        
        // Вызываем метод и получаем сгенерированный UUID
        print("Point = \(location)")
        if let pointId = repository.savePoint( forDrawing: drawingId, coordinate: location, layer: activeLayer) {
            pointMarker.accessibilityIdentifier = pointId.uuidString
        }
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
            
            // Генерируем уникальный идентификатор для полилинии и сохраняем его
            currentPolylineId = UUID()
            layer.setValue(currentPolylineId?.uuidString, forKey: "entityId")
            // Устанавливаем тип сущности, чтобы отличать полилинии от линий
            layer.setValue("polyline", forKey: "entityType")
        }
        
        let path = UIBezierPath()
        if let first = currentPolylinePoints.first {
            path.move(to: first)
            for point in currentPolylinePoints.dropFirst() {
                path.addLine(to: point)
            }
        }
        currentPolylineLayer?.path = path.cgPath
        // Сохраняем массив точек в слое для точного вычисления расстояния
        currentPolylineLayer?.setValue(currentPolylinePoints, forKey: "points")
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
        enableAllCreationButtons() // Разблокировать все кнопки создания
    }
    
    private func cancelCurrentPolyline() {
        currentPolylineLayer?.removeFromSuperlayer()
        currentPolylineLayer = nil
        currentPolylinePoints.removeAll()
        currentPolylineId = nil
    }

    @objc private func savePolylineAction() {
        guard let polylineId = currentPolylineId else { return }
        print("PolyLine = \(currentPolylinePoints)")
        // Сохраняем полилинию с внешним идентификатором
        repository.savePolyline(forDrawing: drawingId, polylineId: polylineId, points: currentPolylinePoints, closed: true, layer: activeLayer)
        cancelCurrentPolyline()
        hidePolylineControlPanel()
        disablePolylineMode()
        loadPolylineMarkers()
        enableAllCreationButtons()
    }
    
    @objc private func closePolylineAction() {
        guard let polylineId = currentPolylineId, let first = currentPolylinePoints.first else { return }
        currentPolylinePoints.append(first)
        updatePolylineLayer()
        print("PolyLine = \(currentPolylinePoints)")
        repository.savePolyline(forDrawing: drawingId, polylineId: polylineId, points: currentPolylinePoints, closed: true, layer: activeLayer)
        cancelCurrentPolyline()
        hidePolylineControlPanel()
        disablePolylineMode()
        loadPolylineMarkers()
        enableAllCreationButtons()
    }
    
    // MARK: - Обработка ввода текста
    @objc private func handleTextTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: pdfContentView)
        let alert = UIAlertController(title: "Введите текст", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Ваш текст"
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  !text.isEmpty else { return }
            print("Text = \(location)")
            self.repository.saveText(forDrawing: self.drawingId, text: text, coordinate: location, layer: self.activeLayer)
            
            self.updateDrawingView()
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
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let image = info[.originalImage] as? UIImage else { return }
            
            if let marker = self.currentPhotoMarker,
               let normalized = marker.normalizedCoordinate,
               let markerId = marker.photoEntityId {
                
                let photoNumber = self.repository.getNextPhotoNumber(forDrawing: self.drawingId)
                
                switch self.currentPhotoOperation {
                case .none:
                    print("PhotoMarker - x = \(normalized.x), y = \(normalized.y)")
                    self.repository.savePhotoMarker(forDrawing: self.drawingId,
                                                    withId: markerId,
                                                    image: image,
                                                    photoNumber: photoNumber,
                                                    timestamp: Date(),
                                                    coordinateX: Double(normalized.x),
                                                    coordinateY: Double(normalized.y)) //здесь абсолютные значение, а не нормализованныые
                    marker.photo = image
                    
                case .retake:
                    if let retakePhotoId = self.currentRetakePhotoId {
                        self.repository.updatePhotoMarker(forDrawing: self.drawingId,
                                                          withId: retakePhotoId,
                                                          image: image,
                                                          timestamp: Date(),
                                                          coordinateX: Double(normalized.x),
                                                          coordinateY: Double(normalized.y))
                        // Если переснимается основное фото, обновляем метку
                        if retakePhotoId == markerId {
                            marker.photo = image
                        } else {
                            // Для дополнительного фото обновляем обложку, устанавливая первую фотографию
                            let photos = self.repository.loadPhotosForMarker(withId: markerId)
                            if let firstPhoto = photos.first {
                                marker.photo = firstPhoto.image
                            }
                        }
                        self.currentRetakePhotoId = nil
                    }
                    
                case .add:
                    // Добавляем дополнительное фото, не затирая основное
                    let newPhotoId = UUID()
                    self.repository.saveAdditionalPhoto(forDrawing: self.drawingId,
                                                        parentMarkerId: markerId,
                                                        newPhotoId: newPhotoId,
                                                        image: image,
                                                        photoNumber: photoNumber,
                                                        timestamp: Date(),
                                                        coordinateX: Double(normalized.x),
                                                        coordinateY: Double(normalized.y))
                    CoreDataManager.shared.context.refreshAllObjects()
                    let photos = self.repository.loadPhotosForMarker(withId: markerId)
                    print("Количество фотографий для маркера \(markerId): \(photos.count)")
                    if let firstPhoto = photos.first {
                        marker.photo = firstPhoto.image
                    }
                }
            }
            
            self.currentPhotoOperation = .none
            self.currentPhotoMarker = nil
            self.photoMarkerTapRecognizer.isEnabled = self.topButtonActive
        }
    }


    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        currentPhotoMarker?.removeFromSuperview()
        currentPhotoMarker = nil
        photoMarkerTapRecognizer.isEnabled = topButtonActive
    }
    
    // MARK: - Работа с фото-маркерами
    @objc private func photoMarkerTapped(_ sender: PhotoMarkerButton) {
        presentPhoto(forMarker: sender)
    }
    
//    private func presentPhoto(_ image: UIImage, forMarker marker: PhotoMarkerButton) {
//        let photoVC = UIViewController()
//        photoVC.view.backgroundColor = .black
//        
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        photoVC.view.addSubview(imageView)
//        NSLayoutConstraint.activate([
//            imageView.topAnchor.constraint(equalTo: photoVC.view.topAnchor),
//            imageView.bottomAnchor.constraint(equalTo: photoVC.view.bottomAnchor),
//            imageView.leadingAnchor.constraint(equalTo: photoVC.view.leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor)
//        ])
//        
//        // Кнопка закрытия
//        let closeButton = UIButton(type: .system)
//        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
//        closeButton.tintColor = .white
//        closeButton.translatesAutoresizingMaskIntoConstraints = false
//        closeButton.addTarget(self, action: #selector(dismissPhotoVC), for: .touchUpInside)
//        photoVC.view.addSubview(closeButton)
//        NSLayoutConstraint.activate([
//            closeButton.topAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            closeButton.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor, constant: -16)
//        ])
//        
//        // Добавляем кнопку удаления фото-маркера
//        let deleteButton = UIButton(type: .system)
//        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
//        deleteButton.tintColor = .red
//        deleteButton.translatesAutoresizingMaskIntoConstraints = false
//        deleteButton.addTarget(self, action: #selector(deletePhotoMarkerAction(_:)), for: .touchUpInside)
//        photoVC.view.addSubview(deleteButton)
//        NSLayoutConstraint.activate([
//            deleteButton.bottomAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            deleteButton.centerXAnchor.constraint(equalTo: photoVC.view.centerXAnchor),
//            deleteButton.widthAnchor.constraint(equalToConstant: 30),
//            deleteButton.heightAnchor.constraint(equalToConstant: 30)
//        ])
//        
//        self.currentViewingMarker = marker
//        present(photoVC, animated: true)
//    }

    
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
            
            print("LoadPhoto = \(markerData.coordinate)")
            markerButton.center = markerData.coordinate
            
            pdfImageView.addSubview(markerButton)
            pdfImageView.bringSubviewToFront(markerButton)
        }
    }
    
    // MARK: - Загрузка точек
    private func loadPointMarkers() {
        let points = repository.loadPoints(forDrawing: drawingId)  // [PointData]
        let markerSize: CGFloat = 10.0
        for pointData in points {
            let marker = UIButton(frame: CGRect(x: 0, y: 0, width: markerSize, height: markerSize))
            marker.backgroundColor = pointData.color
            marker.layer.cornerRadius = markerSize / 2
            marker.clipsToBounds = true
            marker.tag = 1001 // Задаем специальный tag для точек
            print("LoadPoint = \(pointData.coordinate)")
            marker.center = pointData.coordinate
            marker.accessibilityIdentifier = pointData.id.uuidString
            pdfImageView.addSubview(marker)
            pdfImageView.bringSubviewToFront(marker)
        }
    }
    
    // MARK: - Загрузка текстовых меток
    
    @objc private func deletePhotoMarkerAction(_ sender: UIButton) {
        guard let marker = currentViewingMarker, let markerId = marker.photoEntityId else { return }
        repository.deletePhotoMarker(withId: markerId)
        // Удаляем маркер из иерархии представлений
        marker.removeFromSuperview()
        // Обновляем отображение фото-маркеров, чтобы удалённый маркер точно не отображался
        reloadPhotoMarkersUI()
        dismiss(animated: true)
    }
    
    private func reloadPhotoMarkersUI() {
        pdfImageView.subviews.forEach { subview in
            if subview is PhotoMarkerButton {
                subview.removeFromSuperview()
            }
        }
        loadPhotoMarkers()
    }
    
    // Новые свойства для работы со слоями
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

    func setupLayerButton() {
        layerButton = UIButton(type: .custom)
        layerButton.translatesAutoresizingMaskIntoConstraints = false
        layerButton.layer.cornerRadius = 15
        layerButton.layer.borderWidth = 1.0
        layerButton.layer.borderColor = UIColor.gray.cgColor
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
        let layerEntities = repository.loadLayers(forProject: project)
        layers = layerEntities.map { entity in
            LayerData(
                id: entity.id ?? UUID(),
                name: entity.name ?? "",
                color: entity.uiColor ?? .black
            )
        }
        
        if !layers.contains(where: { $0.name == "0" }) {
            let defaultLayer = LayerData(id: UUID(), name: "0", color: .black)
            layers.insert(defaultLayer, at: 0)
            repository.saveLayer(forProject: project, layer: defaultLayer)
        }
        
        let dropdown = UIView()
        dropdown.translatesAutoresizingMaskIntoConstraints = false
        dropdown.backgroundColor = .white
        dropdown.layer.borderWidth = 1.0
        dropdown.layer.borderColor = UIColor.gray.cgColor
        dropdown.layer.cornerRadius = 5.0
        view.addSubview(dropdown)
        self.layerDropdownView = dropdown
        
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
        
        for (index, layer) in layers.enumerated() {
            let layerCell = createLayerCell(for: layer)
            layerCell.tag = index
            let tap = UITapGestureRecognizer(target: self, action: #selector(layerCellTapped(_:)))
            layerCell.addGestureRecognizer(tap)
            stackView.addArrangedSubview(layerCell)
        }
        
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
        container.backgroundColor = (activeLayer?.id == layer.id) ? UIColor.systemGray5 : UIColor.white
        
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
        
        let nameLabel = UILabel()
        nameLabel.text = layer.name
        hStack.addArrangedSubview(nameLabel)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
        
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
                layerButton.backgroundColor = selected.color
                // Обновляем цвет линии в DrawingView:
                drawingView.currentLineColor = selected.color
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
        
        // Если удалённый слой является активным, выбираем слой по умолчанию (имя "0")
        if activeLayer?.id == id {
            let layersFromRepo = repository.loadLayers(forProject: project)
            if let defaultLayerEntity = layersFromRepo.first(where: { $0.name == "0" }) {
                let defaultLayerData = LayerData(
                    id: defaultLayerEntity.id ?? UUID(),
                    name: defaultLayerEntity.name ?? "0",
                    color: defaultLayerEntity.uiColor ?? UIColor.black
                )
                activeLayer = defaultLayerData
                layerButton.backgroundColor = defaultLayerData.color
                drawingView.currentLineColor = defaultLayerData.color
            } else {
                // Если нет слоя "0", можно создать его или установить цвет по умолчанию
                activeLayer = LayerData(id: UUID(), name: "0", color: .black)
                layerButton.backgroundColor = .black
                drawingView.currentLineColor = .black
            }
        }
        
        updateDrawingView()
        hideLayerDropdown()
        showLayerDropdown()
    }


    func updateDrawingView() {
        pdfContentView.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        // Удаляем все дочерние представления (subviews) у pdfImageView, где размещаются точки, текстовые метки и фото-маркеры
        pdfImageView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        drawingView.loadLines([])
    
        loadSavedLines()
        loadPolylineMarkers()
        loadPointMarkers()
        loadTextMarkers()
        loadRectangleMarkers()
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
    
    @objc private func toggleRectangleMode(_ sender: UIButton) {
        if !rectangleModeEnabled {
            rectangleModeEnabled = true
            rectangleToggleButton.setImage(UIImage(named: "rectangle_active"), for: .normal)
            rectangleTapRecognizer.isEnabled = true
            disableAllCreationButtons(except: rectangleToggleButton)
            
            drawingEnabled = false
            polylineModeEnabled = false
            pointCreationEnabled = false
            textModeEnabled = false
        } else {
            rectangleModeEnabled = false
            rectangleToggleButton.setImage(UIImage(named: "rectangle_passive"), for: .normal)
            rectangleTapRecognizer.isEnabled = false
            enableAllCreationButtons()
            rectangleFirstPoint = nil
            rectangleLayer?.removeFromSuperlayer()
            rectangleLayer = nil
        }
    }
    
    @objc private func handleRectangleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: pdfContentView)
        if rectangleFirstPoint == nil {
            rectangleFirstPoint = location
        } else {
            guard let first = rectangleFirstPoint else { return }
            // Определяем координаты так, чтобы первая точка была верхним левым углом, а вторая – нижним правым
            let x = min(first.x, location.x)
            let y = min(first.y, location.y)
            let width = abs(first.x - location.x)
            let height = abs(first.y - location.y)
            let rect = CGRect(x: x, y: y, width: width, height: height)
            
            rectangleLayer?.removeFromSuperlayer()
            
            // Рисуем окончательный прямоугольник
            let layer = CAShapeLayer()
            let strokeColor = activeLayer?.color.cgColor ?? UIColor.red.cgColor
            layer.strokeColor = strokeColor
            layer.lineWidth = 2.0
            layer.fillColor = UIColor.clear.cgColor
            let path = UIBezierPath(rect: rect)
            layer.path = path.cgPath
            pdfContentView.layer.addSublayer(layer)
            
            print("Rectangle = \(rect)")
            repository.saveRectangle(forDrawing: drawingId, rect: rect, layer: activeLayer)
            
            // Сбрасываем первую точку, чтобы можно было начать новый прямоугольник
            rectangleFirstPoint = nil
        }
    }

    
    private func loadRectangleMarkers() {
        if let sublayers = pdfContentView.layer.sublayers {
            for layer in sublayers {
                if let shapeLayer = layer as? CAShapeLayer,
                   let entityType = shapeLayer.value(forKey: "entityType") as? String,
                   entityType == "rectangle" {
                    shapeLayer.removeFromSuperlayer()
                }
            }
        }
        
        let rectangles = repository.loadRectangles(forDrawing: drawingId)  // [RectangleData]
        for rectData in rectangles {
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = rectData.color.cgColor
            shapeLayer.lineWidth = 2.0
            shapeLayer.fillColor = UIColor.clear.cgColor
            print("LoadRectangle = \(rectData.rect)")
            let path = UIBezierPath(rect: rectData.rect)
            shapeLayer.path = path.cgPath
            // Устанавливаем уникальный идентификатор и тип "rectangle" для корректного удаления с помощью ластика
            shapeLayer.setValue(rectData.id.uuidString, forKey: "entityId")
            shapeLayer.setValue("rectangle", forKey: "entityType")
            
            pdfContentView.layer.addSublayer(shapeLayer)
        }
    }

    func disableAllCreationButtons(except activeButton: UIButton) {
        let creationButtons: [UIButton] = [topToggleButton, drawingToggleButton, polylineToggleButton, pointToggleButton, textToggleButton, rectangleToggleButton, eraserToggleButton]
        for button in creationButtons {
            if button != activeButton {
                button.isEnabled = false
            }
        }
    }

    func enableAllCreationButtons() {
        let creationButtons: [UIButton] = [topToggleButton, drawingToggleButton, polylineToggleButton, pointToggleButton, textToggleButton, rectangleToggleButton, eraserToggleButton]
        creationButtons.forEach { $0.isEnabled = true }
    }
    
    // Функция для установки кнопки ластика (вызывается из setupButtons())
    private func setupEraserButton() {
        eraserToggleButton = UIButton(type: .custom)
        eraserToggleButton.translatesAutoresizingMaskIntoConstraints = false
        eraserToggleButton.setImage(UIImage(named: "eraser_passive"), for: .normal)
        eraserToggleButton.addTarget(self, action: #selector(toggleEraserMode(_:)), for: .touchUpInside)
        bottomPanel.addSubview(eraserToggleButton)
        
        NSLayoutConstraint.activate([
            eraserToggleButton.trailingAnchor.constraint(equalTo: rectangleToggleButton.leadingAnchor, constant: -20),
            eraserToggleButton.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            eraserToggleButton.widthAnchor.constraint(equalToConstant: 44),
            eraserToggleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    private func deactivateEraserMode() {
        eraserModeEnabled = false
        eraserToggleButton.setImage(UIImage(named: "eraser_passive"), for: .normal)
        eraserTapRecognizer.isEnabled = false
        enableAllCreationButtons()
    }

    // Функция переключения режима ластика
    @objc private func toggleEraserMode(_ sender: UIButton) {
        if !eraserModeEnabled {
            eraserModeEnabled = true
            eraserToggleButton.setImage(UIImage(named: "eraser_active"), for: .normal)
            eraserTapRecognizer.isEnabled = true
            disableAllCreationButtons(except: eraserToggleButton)
        } else {
            eraserModeEnabled = false
            eraserToggleButton.setImage(UIImage(named: "eraser_passive"), for: .normal)
            eraserTapRecognizer.isEnabled = false
            enableAllCreationButtons()
        }
    }


    // Обработчик касания в режиме ластика
    @objc private func handleEraserTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: pdfContentView)
        print("Tap location in pdfContentView: \(tapLocation)")
        
        // 1. Обработка точек (UIButton с tag 1001)
        for subview in pdfImageView.subviews {
            if let pointButton = subview as? UIButton,
               pointButton.tag == 1001,
               pointButton.frame.size == CGSize(width: 10, height: 10) {
                let convertedCenter = pdfImageView.convert(pointButton.center, to: pdfContentView)
                let distance = hypot(convertedCenter.x - tapLocation.x, convertedCenter.y - tapLocation.y)
                print("Distance to point: \(distance)")
                if distance < 50 {
                    if let idString = pointButton.accessibilityIdentifier,
                       let pointId = UUID(uuidString: idString) {
                        repository.deletePoint(withId: pointId)
                        CoreDataManager.shared.context.refreshAllObjects()
                    }
                    pointButton.removeFromSuperview()
                    updateDrawingView()
                    return
                }
            }
            
            // 2. Обработка текстовых меток (UILabel)
            if let label = subview as? UILabel, label.accessibilityIdentifier != nil {
                let convertedCenter = pdfImageView.convert(label.center, to: pdfContentView)
                let distance = hypot(convertedCenter.x - tapLocation.x, convertedCenter.y - tapLocation.y)
                print("Distance to label: \(distance)")
                if distance < 50 {
                    if let idString = label.accessibilityIdentifier,
                       let textId = UUID(uuidString: idString) {
                        repository.deleteText(withId: textId)
                    }
                    label.removeFromSuperview()
                    updateDrawingView()
                    return
                }
            }
            
            // 3. Обработка фото-маркеров (PhotoMarkerButton)
            if let photoMarker = subview as? PhotoMarkerButton, let markerId = photoMarker.photoEntityId {
                let convertedCenter = pdfImageView.convert(photoMarker.center, to: pdfContentView)
                let distance = hypot(convertedCenter.x - tapLocation.x, convertedCenter.y - tapLocation.y)
                print("Distance to photo marker: \(distance)")
                if distance < 50 {
                    repository.deletePhotoMarker(withId: markerId)
                    photoMarker.removeFromSuperview()
                    updateDrawingView()
                    return
                }
            }
        }
        
        // 4. Обработка CAShapeLayer для линий, полилиний и прямоугольников
        if let sublayers = pdfContentView.layer.sublayers {
            for layer in sublayers {
                if let shapeLayer = layer as? CAShapeLayer, let path = shapeLayer.path {
                    // Определяем тип сущности (если не задан, считаем "line")
                    let entityType = (shapeLayer.value(forKey: "entityType") as? String) ?? "line"
                    var shouldDelete = false
                    
                    if entityType == "line" {
                        let boundingBox = path.boundingBox
                        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
                        let distance = hypot(center.x - tapLocation.x, center.y - tapLocation.y)
                        print("Distance to line: \(distance)")
                        if distance < 50 { shouldDelete = true }
                    } else if entityType == "polyline" {
                        if let points = shapeLayer.value(forKey: "points") as? [CGPoint], points.count >= 2 {
                            var minDistance = CGFloat.greatestFiniteMagnitude
                            for i in 0..<points.count - 1 {
                                let d = distanceFromPoint(tapLocation, toSegmentFrom: points[i], to: points[i+1])
                                minDistance = min(minDistance, d)
                            }
                            print("Minimum distance to polyline: \(minDistance)")
                            if minDistance < 50 { shouldDelete = true }
                        }
                    } else if entityType == "rectangle" {
                        let boundingBox = path.boundingBox
                        let topEdge = distanceFromPoint(tapLocation,
                                                        toSegmentFrom: CGPoint(x: boundingBox.minX, y: boundingBox.minY),
                                                        to: CGPoint(x: boundingBox.maxX, y: boundingBox.minY))
                        let bottomEdge = distanceFromPoint(tapLocation,
                                                           toSegmentFrom: CGPoint(x: boundingBox.minX, y: boundingBox.maxY),
                                                           to: CGPoint(x: boundingBox.maxX, y: boundingBox.maxY))
                        let leftEdge = distanceFromPoint(tapLocation,
                                                         toSegmentFrom: CGPoint(x: boundingBox.minX, y: boundingBox.minY),
                                                         to: CGPoint(x: boundingBox.minX, y: boundingBox.maxY))
                        let rightEdge = distanceFromPoint(tapLocation,
                                                          toSegmentFrom: CGPoint(x: boundingBox.maxX, y: boundingBox.minY),
                                                          to: CGPoint(x: boundingBox.maxX, y: boundingBox.maxY))
                        let minDistance = min(topEdge, bottomEdge, leftEdge, rightEdge)
                        print("Minimum distance to rectangle: \(minDistance)")
                        if minDistance < 50 { shouldDelete = true }
                    }
                    
                    if shouldDelete, let idString = shapeLayer.value(forKey: "entityId") as? String,
                       let entityId = UUID(uuidString: idString) {
                        switch entityType {
                        case "line":
                            repository.deleteLine(withId: entityId)
                        case "polyline":
                            repository.deletePolyline(withId: entityId)
                        case "rectangle":
                            repository.deleteRectangle(withId: entityId)
                        default:
                            break
                        }
                        CoreDataManager.shared.context.refreshAllObjects()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            shapeLayer.removeFromSuperlayer()
                            self.updateDrawingView()
                        }
                        return
                    }
                }
            }
        }
    }

    func distanceFromPoint(_ point: CGPoint, toSegmentFrom p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        if dx == 0 && dy == 0 { return hypot(point.x - p1.x, point.y - p1.y) }
        let t = max(0, min(1, ((point.x - p1.x) * dx + (point.y - p1.y) * dy) / (dx * dx + dy * dy)))
        let projection = CGPoint(x: p1.x + t * dx, y: p1.y + t * dy)
        return hypot(point.x - projection.x, point.y - projection.y)
    }
    
    private func getDrawingName(for drawingId: UUID) -> String {
        let drawings = repository.loadDrawings(for: project)
        if let drawing = drawings.first(where: { $0.id == drawingId }) {
            return drawing.name
        }
        return "Drawing"
    }
    
    @objc private func toggleAudioRecording(_ sender: UIButton) {
        if !isAudioRecordingActive {
            isAudioRecordingActive = true
            audioRecordingButton.setImage(UIImage(named: "audio_stop"), for: .normal)
            showRecordingStatus(with: "Идет запись…")
            disableAllCreationButtons(except: audioRecordingButton)
            startAudioRecording()
        } else {
            guard let recorder = audioRecorder else { return }
            let recordingURL = recorder.url
            isAudioRecordingActive = false
            audioRecordingButton.setImage(UIImage(named: "audio_start"), for: .normal)
            stopAudioRecording()
            showRecordingStatus(with: "Запись сохранена")
            enableAllCreationButtons()
            
            // Загружаем аудиоданные из созданного файла и сохраняем в базу
            if let audioData = try? Data(contentsOf: recordingURL) {
                let drawingName = getDrawingName(for: drawingId)
                repository.saveAudio(forProject: project, audioData: audioData, timestamp: Date(), drawingName: drawingName)
            }
        }
    }

    private func startAudioRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            let tempDir = NSTemporaryDirectory()
            let drawingName = getDrawingName(for: drawingId)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let dateString = formatter.string(from: Date())
            // Формируем имя файла: дата_названиеЧертажа.caf
            let fileName = "\(dateString)_\(drawingName).caf"
            let filePath = tempDir + "/" + fileName
            let url = URL(fileURLWithPath: filePath)
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            print("Ошибка при запуске записи аудио: \(error)")
        }
    }

    private func stopAudioRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    private func showRecordingStatus(with message: String) {
        // Удаляем предыдущий лейбл, если он существует
        recordingStatusLabel?.removeFromSuperview()
        recordingStatusLabel = UILabel()
        recordingStatusLabel?.translatesAutoresizingMaskIntoConstraints = false
        recordingStatusLabel?.text = message
        recordingStatusLabel?.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        recordingStatusLabel?.textColor = .white
        recordingStatusLabel?.textAlignment = .center
        
        guard let containerView = self.presentedViewController?.view ?? self.view else { return }
        
        containerView.addSubview(recordingStatusLabel!)
        NSLayoutConstraint.activate([
            recordingStatusLabel!.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            recordingStatusLabel!.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            recordingStatusLabel!.widthAnchor.constraint(equalToConstant: 200),
            recordingStatusLabel!.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Убираем уведомление через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.recordingStatusLabel?.removeFromSuperview()
        }
    }

//    // вывод бд аудио в консоль
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        printAudioRecords()
//    }
    
    private func printAudioRecords() {
        let fetchRequest: NSFetchRequest<AudioEntity> = AudioEntity.fetchRequest()
        do {
            let audioEntities = try CoreDataManager.shared.context.fetch(fetchRequest)
            for audio in audioEntities {
                let id = audio.id ?? UUID()
                let timestamp = audio.timestamp ?? Date()
                let dataLength = audio.audioData?.count ?? 0
                print("Audio id: \(id), timestamp: \(timestamp), data length: \(dataLength)")
            }
        } catch {
            print("Ошибка выборки аудио: \(error)")
        }
    }
   
    private func presentPhoto(forMarker marker: PhotoMarkerButton) {
        guard let markerId = marker.photoEntityId else {
            print("Маркер не имеет photoEntityId")
            return
        }
        self.currentViewingMarker = marker
        
        let photos = repository.loadPhotosForMarker(withId: markerId)
        if photos.isEmpty {
            print("Нет фото для маркера \(markerId)")
            return
        }
        
        let pagerViewModel = PhotoPagerViewModel(photos: photos)
        let pagerVC = PhotoPagerViewController(viewModel: pagerViewModel)
        
        // Обработка нажатия на кнопку удаления (корзина)
        pagerVC.onDelete = { [weak self, weak pagerVC] in
            guard let self = self,
                  let pagerVC = pagerVC,
                  let marker = self.currentViewingMarker,
                  let currentMarkerId = marker.photoEntityId else { return }
            
            let currentPage = pagerVC.currentPage
            let photoId = pagerVC.photos[currentPage].id
            
            if currentPage == 0 {
                // Удаляем основное фото (фото на обложке)
                // Функция deletePhotoMarker возвращает новый id продвинутой фотографии (если есть)
                if let promotedId = self.repository.deletePhotoMarker(withId: currentMarkerId) {
                    // Обновляем id метки на новый основной
                    marker.photoEntityId = promotedId
                    let updatedPhotos = self.repository.loadPhotosForMarker(withId: promotedId)
                    if let firstPhoto = updatedPhotos.first {
                        marker.photo = firstPhoto.image
                    }
                    pagerVC.updatePhotos(updatedPhotos)
                } else {
                    // Если дополнительных фото нет, удаляем метку полностью
                    _ = self.repository.deletePhotoMarker(withId: currentMarkerId)
                    marker.removeFromSuperview()
                    self.dismiss(animated: true)
                }
            } else {
                // Удаляем дополнительное фото
                self.repository.deletePhotoMarker(withId: photoId)
                let updatedPhotos = self.repository.loadPhotosForMarker(withId: currentMarkerId)
                if let firstPhoto = updatedPhotos.first {
                    marker.photo = firstPhoto.image
                }
                pagerVC.updatePhotos(updatedPhotos)
                // Экран просмотра остается открытым
            }
        }
        
        // Обработка пересъёмки (retake)
        pagerVC.onRetake = { [weak self, weak pagerVC] in
            guard let self = self, let pagerVC = pagerVC else { return }
            let currentPage = pagerVC.currentPage
            self.currentRetakePhotoId = pagerVC.photos[currentPage].id
            self.currentPhotoMarker = self.currentViewingMarker
            self.dismiss(animated: true) {
                self.currentPhotoOperation = .retake
                self.presentCamera()
            }
        }
        
        // Обработка добавления нового фото (add)
        pagerVC.onAdd = { [weak self] in
            guard let self = self else { return }
            self.currentPhotoMarker = self.currentViewingMarker
            self.dismiss(animated: true) {
                self.currentPhotoOperation = .add
                self.presentCamera()
            }
        }
        
        // Обработка аудиозаметки (без изменений)
        pagerVC.onAudio = { [weak self] in
            guard let self = self else { return }
            if !self.isAudioRecordingActive {
                self.isAudioRecordingActive = true
                self.showRecordingStatus(with: "Идет запись…")
                self.startAudioRecording()
            } else {
                guard let recorder = self.audioRecorder else { return }
                let recordingURL = recorder.url
                self.isAudioRecordingActive = false
                self.stopAudioRecording()
                self.showRecordingStatus(with: "Запись сохранена")
                if let audioData = try? Data(contentsOf: recordingURL) {
                    let drawingName = self.getDrawingName(for: self.drawingId)
                    self.repository.saveAudio(forProject: self.project, audioData: audioData, timestamp: Date(), drawingName: drawingName)
                }
            }
        }
        
        // Обработка завершения просмотра
        pagerVC.onDone = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        self.present(pagerVC, animated: true, completion: nil)
    }

    // Метод для переключения режима аудиозаметки
    @objc private func toggleAudioNote(_ sender: UIButton) {
        if !isAudioRecordingActive {
            // Если запись не активна, запускаем запись и меняем изображение на активное
            isAudioRecordingActive = true
            sender.setImage(UIImage(named: "audio_stop"), for: .normal)
            showRecordingStatus(with: "Идет запись…")
            // При необходимости можно отключить остальные кнопки
            startAudioRecording()
        } else {
            // Если запись активна, останавливаем запись и возвращаем исходное изображение
            guard let recorder = audioRecorder else { return }
            let recordingURL = recorder.url
            isAudioRecordingActive = false
            sender.setImage(UIImage(named: "audio_start"), for: .normal)
            stopAudioRecording()
            showRecordingStatus(with: "Запись сохранена")
            if let audioData = try? Data(contentsOf: recordingURL) {
                let drawingName = getDrawingName(for: drawingId)
                repository.saveAudio(forProject: project, audioData: audioData, timestamp: Date(), drawingName: drawingName)
            }
        }
    }

        
//        private func presentPhoto(forMarker marker: PhotoMarkerButton) {
//        // Проверяем, что у маркера установлен идентификатор
//        guard let markerId = marker.photoEntityId else {
//            print("photoEntityId отсутствует")
//            return
//        }
//        
//        // Загружаем все фото, связанные с этим маркером
//        let photos = repository.loadPhotosForMarker(withId: markerId)
//        print("Загружено \(photos.count) фотографий для маркера \(markerId)")
//        
//        // Если фотографии не найдены, выводим предупреждение
//        guard !photos.isEmpty else {
//            let alert = UIAlertController(title: "Ошибка", message: "Фотография не найдена.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            present(alert, animated: true)
//            return
//        }
//        
//        // Создаём контроллер для отображения фотографий
//        let photoVC = UIViewController()
//        photoVC.modalPresentationStyle = .fullScreen
//        photoVC.view.backgroundColor = .white
//        
//        // Если фото только одно, показываем его без возможности пролистывания
//        if photos.count == 1 {
//            let imageView = UIImageView(image: photos[0].image)
//            imageView.contentMode = .scaleAspectFit
//            imageView.translatesAutoresizingMaskIntoConstraints = false
//            photoVC.view.addSubview(imageView)
//            NSLayoutConstraint.activate([
//                imageView.topAnchor.constraint(equalTo: photoVC.view.topAnchor),
//                imageView.leadingAnchor.constraint(equalTo: photoVC.view.leadingAnchor),
//                imageView.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor),
//                imageView.bottomAnchor.constraint(equalTo: photoVC.view.bottomAnchor, constant: -80)
//            ])
//        } else {
//            // Если фото больше одного, используем UIScrollView с UIStackView для пролистывания
//            let scrollView = UIScrollView()
//            scrollView.isPagingEnabled = true
//            scrollView.showsHorizontalScrollIndicator = false
//            scrollView.translatesAutoresizingMaskIntoConstraints = false
//            photoVC.view.addSubview(scrollView)
//            
//            NSLayoutConstraint.activate([
//                scrollView.topAnchor.constraint(equalTo: photoVC.view.topAnchor),
//                scrollView.leadingAnchor.constraint(equalTo: photoVC.view.leadingAnchor),
//                scrollView.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor),
//                scrollView.bottomAnchor.constraint(equalTo: photoVC.view.bottomAnchor, constant: -80) // отводим место для нижней панели
//            ])
//            
//            let stackView = UIStackView()
//            stackView.axis = .horizontal
//            stackView.alignment = .fill
//            stackView.distribution = .fillEqually
//            stackView.translatesAutoresizingMaskIntoConstraints = false
//            scrollView.addSubview(stackView)
//            
//            NSLayoutConstraint.activate([
//                stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//                stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//                stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//                stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//                stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
//            ])
//            
//            for photoData in photos {
//                let imageView = UIImageView(image: photoData.image)
//                imageView.contentMode = .scaleAspectFit
//                imageView.translatesAutoresizingMaskIntoConstraints = false
//                stackView.addArrangedSubview(imageView)
//            }
//        }
//        
//        // Создаём нижнюю панель с кнопками
//        let bottomPanel = UIView()
//        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
//        photoVC.view.addSubview(bottomPanel)
//        
//        NSLayoutConstraint.activate([
//            bottomPanel.heightAnchor.constraint(equalToConstant: 80),
//            bottomPanel.leadingAnchor.constraint(equalTo: photoVC.view.leadingAnchor),
//            bottomPanel.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor),
//            bottomPanel.bottomAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.bottomAnchor)
//        ])
//        
//        // Кнопка "Удалить"
//        let deleteButton = UIButton(type: .system)
//        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
//        deleteButton.tintColor = .red
//        deleteButton.translatesAutoresizingMaskIntoConstraints = false
//        deleteButton.addTarget(self, action: #selector(deletePhotoMarkerAction(_:)), for: .touchUpInside)
//        
//        // Кнопка "Переснять"
//        let retakeButton = UIButton(type: .custom)
//        retakeButton.setImage(UIImage(named: "change"), for: .normal)
//        retakeButton.translatesAutoresizingMaskIntoConstraints = false
//        retakeButton.addTarget(self, action: #selector(retakePhotoForMarker), for: .touchUpInside)
//        retakeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        retakeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
//        
//        // Кнопка "Добавить"
//        let addButton = UIButton(type: .custom)
//        addButton.setImage(UIImage(named: "add"), for: .normal)
//        addButton.translatesAutoresizingMaskIntoConstraints = false
//        addButton.addTarget(self, action: #selector(addPhotoToMarker), for: .touchUpInside)
//        addButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        addButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
//        
//        // Новая кнопка "Аудиозаметка" с переключением изображения:
//        let audioButton = UIButton(type: .custom)
//        // Устанавливаем начальное изображение (неактивное состояние)
//        audioButton.setImage(UIImage(named: "audio_start"), for: .normal)
//        audioButton.translatesAutoresizingMaskIntoConstraints = false
//        audioButton.addTarget(self, action: #selector(toggleAudioNote(_:)), for: .touchUpInside)
//        audioButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        audioButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
//        
//        // Кнопка "Готово"
//        let doneButton = UIButton(type: .custom)
//        doneButton.setImage(UIImage(named: "accept"), for: .normal)
//        doneButton.translatesAutoresizingMaskIntoConstraints = false
//        doneButton.addTarget(self, action: #selector(dismissPhotoVC), for: .touchUpInside)
//        doneButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        doneButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
//        
//        // Организуем кнопки в StackView
//        let buttonStack = UIStackView(arrangedSubviews: [deleteButton, retakeButton, addButton, audioButton, doneButton])
//        buttonStack.axis = .horizontal
//        buttonStack.alignment = .center
//        buttonStack.distribution = .equalSpacing
//        buttonStack.translatesAutoresizingMaskIntoConstraints = false
//        bottomPanel.addSubview(buttonStack)
//        
//        NSLayoutConstraint.activate([
//            buttonStack.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
//            buttonStack.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20),
//            buttonStack.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor)
//        ])
//        
//        self.currentViewingMarker = marker
//        present(photoVC, animated: true)
//    }
//
//    @objc private func toggleAudioNote(_ sender: UIButton) {
//        if !isAudioRecordingActive {
//            // Если запись не активна, запускаем запись и меняем изображение на активное
//            isAudioRecordingActive = true
//            sender.setImage(UIImage(named: "audio_stop"), for: .normal)
//            showRecordingStatus(with: "Идет запись…")
//            // Если нужно, отключите остальные кнопки (аналог disableAllCreationButtons)
//            startAudioRecording()
//        } else {
//            // Если запись активна, останавливаем запись и возвращаем исходное изображение
//            guard let recorder = audioRecorder else { return }
//            let recordingURL = recorder.url
//            isAudioRecordingActive = false
//            sender.setImage(UIImage(named: "audio_start"), for: .normal)
//            stopAudioRecording()
//            showRecordingStatus(with: "Запись сохранена")
//            // Если нужно, включите обратно остальные кнопки (аналог enableAllCreationButtons)
//            if let audioData = try? Data(contentsOf: recordingURL) {
//                let drawingName = getDrawingName(for: drawingId)
//                repository.saveAudio(forProject: project, audioData: audioData, timestamp: Date(), drawingName: drawingName)
//            }
//        }
//    }

    enum PhotoOperation { 
        case none
        case retake
        case add }
    
    // Метод для пересъёмки фото – закрывает текущий экран, затем открывает камеру в режиме пересъёмки.
    @objc private func retakePhotoForMarker() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.currentPhotoOperation = .retake
            self.presentCamera()
        }
    }
    
    // Метод для добавления нового фото – закрывает текущий экран, затем открывает камеру в режиме добавления.
    @objc private func addPhotoToMarker() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.currentPhotoOperation = .add
            self.presentCamera()
        }
    }
    
    private var currentPhotoOperation: PhotoOperation = .none

}
