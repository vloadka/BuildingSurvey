//
//  DrawingView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 05.03.2025.
//

import UIKit

struct DrawingLine {
    let start: CGPoint
    let end: CGPoint
    let color: UIColor
}

class DrawingView: UIView {
    private var points: [CGPoint] = [] // Хранит точки для рисования
    private var lines: [DrawingLine] = []
    var currentLineColor: UIColor = .black  // Добавляем свойство для текущего цвета
    
    // Замыкание, вызываемое после рисования линии
    var onLineDrawn: ((CGPoint, CGPoint) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizers()
    }

    // Настройка распознавателя жестов
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }

    // Обработка касаний
    @objc private func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
           let location = gestureRecognizer.location(in: self)
           if points.isEmpty {
               points.append(location)
           } else if points.count == 1 {
               let startPoint = points[0]
               let endPoint = location
               // Используем currentLineColor для линии
               lines.append(DrawingLine(start: startPoint, end: endPoint, color: currentLineColor))
               onLineDrawn?(startPoint, endPoint)
               points.removeAll()
           }
           setNeedsDisplay()
       }

    // Отображение линий
    override func draw(_ rect: CGRect) {
            super.draw(rect)
            for line in lines {
                let path = UIBezierPath()
                path.move(to: line.start)
                path.addLine(to: line.end)
                line.color.setStroke()  // Теперь используем сохранённый цвет
                path.lineWidth = 2
                path.stroke()
            }
        }
    
    
    // Загрузка сохраненных линий
    func loadLines(_ savedLines: [DrawingLine]) {
        self.lines = savedLines
        setNeedsDisplay()
    }
    
    
func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor) {
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shapeLayer)
    }

}
