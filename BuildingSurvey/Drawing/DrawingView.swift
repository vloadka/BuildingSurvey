//
//  DrawingView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 05.03.2025.
//

import UIKit

class DrawingView: UIView {
    private var points: [CGPoint] = [] // Хранит точки для рисования
    private var lines: [Line] = [] // Хранит линии

    // Замыкание, которое вызывается после рисования линии
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
            points.append(location) // Запоминаем первую точку
        } else if points.count == 1 {
            let startPoint = points[0]
            let endPoint = location
            lines.append(Line(start: startPoint, end: endPoint))
            // Вызовем замыкание для сохранения линии
            onLineDrawn?(startPoint, endPoint)
            // Очищаем список точек для следующей линии
            points.removeAll()
        }
        // Перерисовываем
        setNeedsDisplay()
    }

    // Отображение линий
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        for line in lines {
            let path = UIBezierPath()
            path.move(to: line.start)
            path.addLine(to: line.end)
            UIColor.black.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }

    // Загрузка сохраненных линий
    func loadLines(_ savedLines: [Line]) {
        self.lines = savedLines
        setNeedsDisplay() // Обновляем экран
    }
}

