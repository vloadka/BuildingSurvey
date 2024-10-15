//
//  ProjectListView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

struct ProjectListView: View {
    @ObservedObject var viewModel: ProjectListViewModel
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    // Действие для кнопки настроек
                }) {
                    Image(systemName: "gear")
                        .padding()
                }
                Spacer()
                Button(action: {
                    // Действие для кнопки профиля
                }) {
                    Image(systemName: "person.crop.circle")
                        .padding()
                }
            }
            
            Text("Мои проекты")
                .font(.largeTitle)
            
            List(viewModel.projects) { project in
                Text(project.name)
            }
         
            Spacer()
            
            NavigationLink(destination: CreateProjectView(viewModel: CreateProjectViewModel(repository: viewModel.repository))) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
            .padding()
        }
    }
}
