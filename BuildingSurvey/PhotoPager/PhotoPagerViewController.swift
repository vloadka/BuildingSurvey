//
//  PhotoPagerViewController.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 03.04.2025.
//
import UIKit

class PhotoPagerViewController: UIViewController {
    private let viewModel: PhotoPagerViewModel
    private var pagerView: PhotoPagerView!
    
    // Добавляем вычисляемые свойства для доступа к данным модели
    var currentPage: Int {
        return viewModel.currentPage
    }
    
    var photos: [PhotoMarkerData] {
        return viewModel.photos
    }
    
    // Замыкания для обработки нажатий на кнопки нижней панели.
    var onDelete: (() -> Void)?
    var onRetake: (() -> Void)?
    var onAdd: (() -> Void)?
    var onAudio: (() -> Void)?
    var onDone: (() -> Void)?

    // Нижняя панель с кнопками, как в оригинале
    private let bottomPanel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    // Кнопки нижней панели
    private let deleteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "trash"), for: .normal)
        btn.tintColor = .red
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let retakeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "change"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return btn
    }()

    private let addButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "add"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return btn
    }()

    private let audioButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "audio_start"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return btn
    }()

    private let doneButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "accept"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return btn
    }()

    init(viewModel: PhotoPagerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBottomPanel()
        setupPagerView()
        
        viewModel.currentPageChanged = { [weak self] page in
            // Здесь можно обновлять UI, если требуется
        }
        
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        retakeButton.addTarget(self, action: #selector(retakeAction), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addAction), for: .touchUpInside)
        audioButton.addTarget(self, action: #selector(audioAction), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
    }

    private func setupPagerView() {
        pagerView = PhotoPagerView(viewModel: viewModel)
        pagerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pagerView)
        
        NSLayoutConstraint.activate([
            pagerView.topAnchor.constraint(equalTo: view.topAnchor),
            pagerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagerView.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor)
        ])
    }

    private func setupBottomPanel() {
        view.addSubview(bottomPanel)
        
        NSLayoutConstraint.activate([
            bottomPanel.heightAnchor.constraint(equalToConstant: 80),
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let buttonStack = UIStackView(arrangedSubviews: [deleteButton, retakeButton, addButton, audioButton, doneButton])
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.distribution = .equalSpacing
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        bottomPanel.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20),
            buttonStack.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor)
        ])
    }
    
    func updatePhotos(_ newPhotos: [PhotoMarkerData]) {
       viewModel.photos = newPhotos
       // Обновляем текущую страницу через публичный метод, если он есть, или корректируем значение
       // Здесь можно вызвать, например, viewModel.updateCurrentPage(to: …)
       reloadData()
    }
   
    func reloadData() {
        pagerView.removeFromSuperview()
        setupPagerView()
    }

    @objc private func deleteAction() {
        onDelete?()
    }

    @objc private func retakeAction() {
        onRetake?()
    }

    @objc private func addAction() {
        onAdd?()
    }

    @objc private func audioAction() {
        onAudio?()
    }

    @objc private func doneAction() {
        onDone?()
    }
}

