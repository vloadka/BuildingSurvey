//
//  PhotoPagerViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 03.04.2025.
//
import UIKit

class PhotoPagerViewModel {
    // Массив фотографий для отображения
    var photos: [PhotoMarkerData]
    
    // Замыкание для уведомления об изменении текущей страницы
    var currentPageChanged: ((Int) -> Void)?

    private(set) var currentPage: Int = 0 {
        didSet {
            currentPageChanged?(currentPage)
        }
    }

    init(photos: [PhotoMarkerData]) {
        self.photos = photos
    }

    func updateCurrentPage(to page: Int) {
        currentPage = page
    }

}
