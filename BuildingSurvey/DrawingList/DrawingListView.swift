//
//  DrawingListView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 09.02.2025.
//

import SwiftUI

struct DrawingListView: View {
    let project: Project
    @StateObject private var viewModel: DrawingListViewModel
    @State private var isAddingDrawing = false
    @State private var showAlert = false
    @State private var drawingToDelete: Drawing? = nil
    @State private var selectedDrawing: Drawing? = nil

    init(project: Project, repository: GeneralRepository) {
        self.project = project
        _viewModel = StateObject(wrappedValue: DrawingListViewModel(repository: repository, project: project))
    }

    var body: some View {
        VStack {
            Text("Чертежи для проекта: \(project.name)")
                .font(.title)
                .padding()

            if viewModel.drawings.isEmpty {
                Text("Нет доступных чертежей")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.drawings, id: \.self) { drawing in
                        HStack {
                            Image(systemName: "doc.text")
                            Text(drawing.name)
                            Spacer()
                            Button(action: {
                                drawingToDelete = drawing
                                showAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDrawing = drawing
                        }
                    }
                }
            }

            Button("Добавить чертеж") {
                isAddingDrawing = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .tint(.red)
            .sheet(isPresented: $isAddingDrawing) {
                AddDrawingView(project: project, repository: viewModel.repository) {
                    viewModel.loadDrawings() // Обновляем список после добавления
                }
            }

            Spacer()
        }
        .onAppear {
            viewModel.loadDrawings()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Вы точно хотите удалить чертеж?"),
                message: Text("Это действие невозможно отменить."),
                primaryButton: .destructive(Text("Удалить")) {
                    if let drawingToDelete = drawingToDelete {
                        viewModel.deleteDrawing(drawing: drawingToDelete)
                    }
                },
                secondaryButton: .cancel {
                    drawingToDelete = nil
                }
            )
        }
        .background(
            NavigationLink(
                destination: PDFViewer(
                    pdfURL: URL(fileURLWithPath: selectedDrawing?.filePath ?? ""),
                    drawingId: selectedDrawing?.id ?? UUID(),
                    repository: GeneralRepository(),
                    project: project    // Используем экземпляр проекта, а не тип
                )
                .navigationTitle(selectedDrawing?.name ?? ""),
                isActive: Binding(
                    get: { selectedDrawing != nil },
                    set: { if !$0 { selectedDrawing = nil } }
                )
            ) {
                EmptyView()
            }
        )
    }
}
