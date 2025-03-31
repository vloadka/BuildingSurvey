//
//  DrawingListView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 09.02.2025.
//

import SwiftUI

enum FileTab: String, CaseIterable {
    case drawings = "Чертежи"
    case audio = "Аудиозаметки"
}

struct DrawingListView: View {
    let project: Project
    @StateObject private var viewModel: DrawingListViewModel
    @State private var isAddingDrawing = false
    @State private var showAlert = false
    @State private var drawingToDelete: Drawing? = nil
    @State private var selectedDrawing: Drawing? = nil
    @State private var selectedTab: FileTab = .drawings

    init(project: Project, repository: GeneralRepository) {
        self.project = project
        _viewModel = StateObject(wrappedValue: DrawingListViewModel(repository: repository, project: project))
    }

    var body: some View {
        VStack {
            Text("Файлы для проекта: \(project.name)")
                .font(.title)
                .padding()

            Picker("", selection: $selectedTab) {
                ForEach(FileTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == .drawings {
                // Список чертежей (код из существующего DrawingListView)
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
                Button("Добавить чертёж") {
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
            } else {
                // Вкладка аудиозаметок
                AudioNotesView(project: project, repository: viewModel.repository)
            }
            Spacer()
        }
        .onAppear {
            viewModel.loadDrawings()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Вы точно хотите удалить чертёж?"),
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
                    repository: viewModel.repository,
                    project: project
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
