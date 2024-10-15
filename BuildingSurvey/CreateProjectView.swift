//
//  CreateProjectView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

struct CreateProjectView: View {
    @State private var projectName: String = ""
    @ObservedObject var viewModel: CreateProjectViewModel
    @Environment(\.dismiss) var dismiss  // Используется для возврата к предыдущему экрану
    @State private var showError: Bool = false // Переменная для отображения ошибки
    
    var body: some View {
        VStack {
            TextField("Название проекта", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if showError {
                Text("Название проекта не может быть пустым.")
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
            }
            
            Button(action: {
                if projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showError = true // Показываем ошибку, если название пустое
                } else {
                    viewModel.saveProject(name: projectName)
                    dismiss() // Возвращаемся на предыдущий экран после сохранения
                }
            }) {
                Text("Сохранить")
                    .font(.headline)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
}
