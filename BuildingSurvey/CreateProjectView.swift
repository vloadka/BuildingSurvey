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
    @Environment(\.dismiss) var dismiss  // Используем для возврата
    
    var body: some View {
        VStack {
            TextField("Название проекта", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                viewModel.saveProject(name: projectName)
                dismiss() // После сохранения, вернуться на предыдущий экран
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
