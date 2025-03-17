//
//  AddLayerViewController.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 14.03.2025.
//

import UIKit

class AddLayerViewController: UIViewController, UIColorPickerViewControllerDelegate {
    
    // Замыкание, которое возвращает название слоя и выбранный цвет
    var completion: ((String, UIColor) -> Void)?
    
    private let nameTextField: UITextField = {
       let tf = UITextField()
       tf.placeholder = "Название слоя"
       tf.borderStyle = .roundedRect
       tf.translatesAutoresizingMaskIntoConstraints = false
       return tf
    }()
    
    private let colorPreview: UIView = {
       let view = UIView()
       view.backgroundColor = .black
       view.layer.borderColor = UIColor.gray.cgColor
       view.layer.borderWidth = 1.0
       view.layer.cornerRadius = 5.0
       view.translatesAutoresizingMaskIntoConstraints = false
       return view
    }()
    
    private let selectColorButton: UIButton = {
       let btn = UIButton(type: .system)
       btn.setTitle("Выбрать цвет", for: .normal)
       btn.translatesAutoresizingMaskIntoConstraints = false
       return btn
    }()
    
    private let saveButton: UIButton = {
       let btn = UIButton(type: .system)
       btn.setTitle("Сохранить", for: .normal)
       btn.translatesAutoresizingMaskIntoConstraints = false
       return btn
    }()
    
    private let cancelButton: UIButton = {
       let btn = UIButton(type: .system)
       btn.setTitle("Отмена", for: .normal)
       btn.translatesAutoresizingMaskIntoConstraints = false
       return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(nameTextField)
        view.addSubview(colorPreview)
        view.addSubview(selectColorButton)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
        
        setupConstraints()
        
        selectColorButton.addTarget(self, action: #selector(selectColorTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            colorPreview.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            colorPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            colorPreview.widthAnchor.constraint(equalToConstant: 50),
            colorPreview.heightAnchor.constraint(equalToConstant: 50),
            
            selectColorButton.centerYAnchor.constraint(equalTo: colorPreview.centerYAnchor),
            selectColorButton.leadingAnchor.constraint(equalTo: colorPreview.trailingAnchor, constant: 20),
            
            saveButton.topAnchor.constraint(equalTo: colorPreview.bottomAnchor, constant: 40),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func selectColorTapped() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = colorPreview.backgroundColor ?? .black
        present(colorPicker, animated: true, completion: nil)
    }
    
    // Метод вызывается при изменении цвета в цветопикере
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        colorPreview.backgroundColor = viewController.selectedColor
    }
    
    @objc func saveTapped() {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        let selectedColor = colorPreview.backgroundColor ?? .black
        completion?(name, selectedColor)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
}
