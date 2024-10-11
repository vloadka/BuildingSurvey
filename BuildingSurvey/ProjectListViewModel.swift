//
//  ProjectListViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    
    func createProject() {
        // Логика для перехода на страницу создания проекта
    }
    
    func addProject(name: String) {
        let newProject = Project(name: name)
        projects.append(newProject)
    }
}
