//
//  ProjectListView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

struct ProjectListView: View {
    @StateObject var viewModel = ProjectListViewModel(repository: GeneralRepository())
    @State private var showDeleteAlert: Bool = false // Флаг для отображения предупреждения
    @State private var projectToDelete: Project? = nil // Проект, который нужно удалить
    @State private var selectedProject: Project? = nil
        
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    // Действие для кнопки настроек
                }) {
                    Image("settings")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding()
                }
                
                Spacer()
                
                Text("Мои проекты")
                    .font(.largeTitle)
                
                Spacer()
                
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .padding()
                }
            }
            
            List(viewModel.uiState.projects) { project in
                ProjectRow(project: project, onDelete: {
                    projectToDelete = project // Сохраняем проект, который нужно удалить
                    showDeleteAlert = true // Показываем предупреждение
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
                    .foregroundColor(.red)
            }
            .padding()
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Вы точно хотите удалить проект?"),
                message: Text("Это действие невозможно отменить."),
                primaryButton: .destructive(Text("Удалить")) {
                    if let project = projectToDelete {
                        viewModel.deleteProject(id: project.id)
                    }
                },
                secondaryButton: .cancel {
                    projectToDelete = nil // Отменяем выбранный проект
                }
            )
        }
    }
}


struct ProjectRow: View {
    let project: Project
    let onDelete: () -> Void
    @State private var isActive = false  // Для управления переходом

    var body: some View {
        VStack {
            NavigationLink(
                destination: DrawingListView(project: project, repository: GeneralRepository()),
                isActive: $isActive
            ) {
                EmptyView()
            }
            .hidden() // Скрываем сам NavigationLink
            
            // Обновлённый блок: создаём UIImage из coverImageData, если оно есть
            if let data = project.coverImageData, let uiImage = UIImage(data: data) {
                createImageView(image: Image(uiImage: uiImage))
                    .onTapGesture {
                        isActive = true  // Активируем переход
                    }
            } else {
                createImageView(image: Image("Default_photo"))
                    .onTapGesture {
                        isActive = true
                    }
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
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding()
    }
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
