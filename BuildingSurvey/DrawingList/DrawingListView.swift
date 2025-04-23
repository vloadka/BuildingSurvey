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
    let repository: GeneralRepository
    let sendRepository: SendRepository

    // существующие стейты
    @State private var isAddingDrawing = false
    @State private var showAlert = false
    @State private var drawingToDelete: Drawing? = nil
    @State private var selectedDrawing: Drawing? = nil
    @State private var selectedTab: FileTab = .drawings

    // новые стейты для масштаба
    @State private var showScaleInput = false
    @State private var scaleText = "1:100"
    @State private var navigateToPDF = false

    init(project: Project, repository: GeneralRepository, sendRepository: SendRepository) {
        self.project = project
        self.repository = repository
        self.sendRepository = sendRepository  // ← сохранили

        _viewModel = StateObject(
            wrappedValue: DrawingListViewModel(
                repository: repository,
                project: project,
                sendRepository: sendRepository   // ← прокинули в VM
            )
        )
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
                                Button {
                                    drawingToDelete = drawing
                                    showAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // сначала сохраняем выбранный чертёж, показываем диалог масштаба
                                selectedDrawing = drawing
                                scaleText = "1:100" // или можно вытянуть из drawing.scale, если уже был
                                showScaleInput = true
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
                    AddDrawingView(
                        project: project,
                        repository: viewModel.repository,
                        sendRepository: viewModel.sendRepository
                    ) {
                        viewModel.loadDrawings()
                    }
                }

            } else {
                AudioNotesView(project: project, repository: viewModel.repository)
            }

            Spacer()
        }
        .onAppear { 
            viewModel.loadDrawings()
            if viewModel.drawings.isEmpty {
                Task { await viewModel.fetchDrawingsFromServer() }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Вы точно хотите удалить чертёж?"),
                message: Text("Это действие невозможно отменить."),
                primaryButton: .destructive(Text("Удалить")) {
                    if let toDelete = drawingToDelete {
                        viewModel.deleteDrawing(toDelete)
                    }
                },
                secondaryButton: .cancel {
                    drawingToDelete = nil
                }
            )
        }
        // скрытая навигация к PDFViewer
        .background(
            NavigationLink(
                destination:
                    PDFViewer(
                        pdfURL: URL(fileURLWithPath: selectedDrawing?.filePath ?? ""),
                        drawingId: selectedDrawing?.id ?? UUID(),
                        repository: viewModel.repository,
                        project: project,
                        scale: selectedDrawing?.scale ?? 1.0
                    )
                    .navigationTitle(selectedDrawing?.name ?? ""),
                isActive: $navigateToPDF
            ) {
                EmptyView()
            }
        )
        // Sheet для ввода масштаба
        .sheet(isPresented: $showScaleInput) {
          ScaleInputView(isPresented: $showScaleInput, text: $scaleText) { input in
            // Разбиваем и валидируем ввод десятков
            let parts = input.split(separator: ":").map(String.init)
            guard parts.count == 2,
                  let a = Double(parts[0]), a > 0,
                  let b = Double(parts[1]), b > 0,
                  let drawing = selectedDrawing
            else { return }

            let resultScale = a / b

            // 1) Сохраняем новый масштаб в Core Data и в локальной модели
            viewModel.repository.updateDrawingScale(drawingId: drawing.id, scale: resultScale)
            selectedDrawing?.scale = resultScale

            // 2) Асинхронно скачиваем PDF и сохраняем путь
            Task {
              do {
                let fileURL = try await viewModel.prepareDrawingFile(drawing)
                selectedDrawing?.filePath = fileURL.path

                // 3) Переключаемся на экран просмотра уже из MainActor
                await MainActor.run {
                    showScaleInput = false
                    navigateToPDF = true
                }
              } catch {
                // здесь можно показать Alert об ошибке
                print("Не удалось загрузить чертёж:", error.localizedDescription)
              }
            }
          }
        }
    }
}

