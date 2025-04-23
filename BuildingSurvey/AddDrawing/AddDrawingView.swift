//
//  AddDrawingView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 09.02.2025.
//

import SwiftUI

struct AddDrawingView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddDrawingViewModel
    @State private var fileName: String = ""
    
    let project: Project
    let repository: GeneralRepository
    let sendRepository: SendRepository
    var onDrawingAdded: () -> Void
    
    init(project: Project, repository: GeneralRepository, sendRepository: SendRepository, onDrawingAdded: @escaping () -> Void) {
        self.project = project
        self.repository = repository
        self.sendRepository = sendRepository
        self.onDrawingAdded = onDrawingAdded
        _viewModel = StateObject(wrappedValue: AddDrawingViewModel(generalRepository: repository, sendRepository: sendRepository))
    }

    var body: some View {
        VStack {
            TextField("Название чертежа", text: $viewModel.drawingName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if !fileName.isEmpty {
                Text("Выбран файл: \(fileName)")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Button("Выбрать PDF") {
                viewModel.isDocumentPickerPresented = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .tint(.black)
            .sheet(isPresented: $viewModel.isDocumentPickerPresented) {
                LoadPDF(
                    selectedPDF: $viewModel.selectedPDF,
                    showError: $viewModel.showError,
                    fileName: $fileName,
                    project: project
                )
            }
            
            Button("Сохранить") {
                viewModel.saveDrawing(for: project) {
                    onDrawingAdded()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .buttonStyle(.bordered)
            .padding()
            .tint(.green)
            .disabled(viewModel.selectedPDF == nil || viewModel.drawingName.isEmpty)
            
            if viewModel.showError {
                Text("Ошибка при загрузке файла.")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}


