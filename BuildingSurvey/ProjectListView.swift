//
//  ProjectListView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

struct ProjectListView: View {
    @StateObject var viewModel = ProjectListViewModel(repository: GeneralRepository())
    
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
            
            List(viewModel.uiState.projects.filter { $0.isDeleted == 0 }) { project in
                ProjectRow(project: project, onDelete: {
                    viewModel.deleteProject(id: project.id)
                })
                .listRowInsets(EdgeInsets())
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
                .padding(.vertical, 5)
            }
            .listStyle(PlainListStyle())
            
            Spacer()
            
            NavigationLink(destination: {
                CreateProjectView(viewModel: CreateProjectViewModel(repository: viewModel.repository))
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            .padding()
        }
    }
}

struct ProjectRow: View {
    let project: Project
    let onDelete: () -> Void

    var body: some View {
        VStack {
            if let imagePath = project.projectFilePath, !imagePath.isEmpty, let image = UIImage(contentsOfFile: imagePath) {
                createImageView(image: Image(uiImage: image))
            } else {
                createImageView(image: Image("Default_photo"))
            }
            
            HStack {
                Text(project.name)
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .padding()
    }
    
    private func createImageView(image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .clipped()
            .cornerRadius(10)
            .padding(.bottom, 5)
    }
}
