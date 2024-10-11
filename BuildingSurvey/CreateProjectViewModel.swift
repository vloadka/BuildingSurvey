//
//  CreateProjectViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

class CreateProjectViewModel: ObservableObject {
    var projectListViewModel: ProjectListViewModel
    
    init(projectListViewModel: ProjectListViewModel) {
        self.projectListViewModel = projectListViewModel
    }
    
    func saveProject(name: String) {
        projectListViewModel.addProject(name: name)
    }
}
