//
//  BuildingSurveyApp.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 18.09.2024.
//

import SwiftUI

@main
struct BuildingSurveyApp: App {
    var projectRepository = ProjectRepository()
    
    var body: some Scene {
        WindowGroup {
            ContentView(repository: projectRepository)
        }
    }
}
