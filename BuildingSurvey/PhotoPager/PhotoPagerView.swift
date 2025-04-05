//
//  PhotoPagerView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 03.04.2025.
//
import UIKit

// Кастомный UIScrollView для зумирования отдельной фотографии
class PhotoZoomingView: UIScrollView, UIScrollViewDelegate {
    let imageView: UIImageView
    private var initialZoomSet = false

    init(photo: UIImage) {
        imageView = UIImageView(image: photo)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = imageView.image else { return }
        let widthScale = bounds.width / image.size.width
        let heightScale = bounds.height / image.size.height
        let minScale = min(widthScale, heightScale)
        minimumZoomScale = minScale
        maximumZoomScale = minScale * 3
        if !initialZoomSet {
            zoomScale = minScale
            initialZoomSet = true
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Основной вид для отображения фотографий с возможностью перелистывания, зумирования и отображением номера фото
class PhotoPagerView: UIView, UIScrollViewDelegate {
    private let viewModel: PhotoPagerViewModel
    private var stackViewWidthConstraint: NSLayoutConstraint?
    
    private let scrollView: UIScrollView = {
       let sv = UIScrollView()
       sv.isPagingEnabled = true
       sv.showsHorizontalScrollIndicator = false
       sv.translatesAutoresizingMaskIntoConstraints = false
       return sv
    }()
    
    private let stackView: UIStackView = {
       let sv = UIStackView()
       sv.axis = .horizontal
       sv.alignment = .fill
       sv.distribution = .fillEqually
       sv.translatesAutoresizingMaskIntoConstraints = false
       return sv
    }()
    
    private let pageControl: UIPageControl = {
       let pc = UIPageControl()
       pc.translatesAutoresizingMaskIntoConstraints = false
       return pc
    }()
    
    // Новый UILabel для отображения текста "X из Y"
    private let pageNumberLabel: UILabel = {
       let label = UILabel()
       label.textAlignment = .center
       label.textColor = .black
       label.font = UIFont.systemFont(ofSize: 14)
       label.translatesAutoresizingMaskIntoConstraints = false
       return label
    }()
    
    init(viewModel: PhotoPagerViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
        configurePhotos()
        pageControl.numberOfPages = viewModel.photos.count
        updatePageNumberLabel(currentPage: viewModel.currentPage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        addSubview(pageControl)
        addSubview(pageNumberLabel)
        
        scrollView.delegate = self
        
        NSLayoutConstraint.activate([
            // ScrollView заполняет весь контейнер
            scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            // StackView привязан к contentLayoutGuide scrollView
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            // Высота StackView равна высоте scrollView
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        // Ограничение для ширины stackView: ширина scrollView * количество фотографий
        stackViewWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: self.frame.width * CGFloat(viewModel.photos.count))
        stackViewWidthConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            // Размещение pageControl внизу по центру
            pageControl.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            pageControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            // Размещение pageNumberLabel над pageControl
            pageNumberLabel.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -5),
            pageNumberLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
    
    private func configurePhotos() {
        for photoData in viewModel.photos {
            let zoomingView = PhotoZoomingView(photo: photoData.image)
            zoomingView.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(zoomingView)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let scrollWidth = scrollView.frame.width
        stackViewWidthConstraint?.constant = scrollWidth * CGFloat(viewModel.photos.count)
    }
    
    private func updatePageNumberLabel(currentPage: Int) {
        pageNumberLabel.text = "\(currentPage + 1) из \(viewModel.photos.count)"
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        viewModel.updateCurrentPage(to: page)
        pageControl.currentPage = page
        updatePageNumberLabel(currentPage: page)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
            viewModel.updateCurrentPage(to: page)
            pageControl.currentPage = page
            updatePageNumberLabel(currentPage: page)
        }
    }
}

