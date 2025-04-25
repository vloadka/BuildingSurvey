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

    @State private var isAddingDrawing = false
    @State private var showAlert = false
    @State private var drawingToDelete: Drawing? = nil
    @State private var selectedDrawing: Drawing? = nil
    @State private var selectedTab: FileTab = .drawings

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
                                   selectedDrawing = drawing
                                  // Если масштаб уже ненулевой — сразу открываем PDF
                                if let s = drawing.scale, s > 0 {
                                    Task {
                                        do {
                                            // 1) скачиваем или находим локальный файл
                                            let fileURL = try await viewModel.prepareDrawingFile(drawing)
                                            // 2) обновляем selectedDrawing, чтобы PDFViewer получил корректный путь
                                            await MainActor.run {
                                                selectedDrawing?.filePath = fileURL.path
                                                // скрываем input (на случай если он был открыт)
                                                showScaleInput = false
                                                // 3) переходим в PDFViewer
                                                navigateToPDF = true
                                            }
                                        } catch {
                                            print("Не удалось загрузить чертёж:", error)
                                        }
                                    }
                                } else {
                                // Первый раз — предлагаем ввести
                                scaleText = "1:100"
                                showScaleInput = true
                                }
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
                        scale: 1.0
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
                // 1) валидируем и вычисляем
                let parts = input.split(separator: ":").map(String.init)
                guard parts.count == 2,
                      let a = Double(parts[0]), let b = Double(parts[1]),
                      var drawing = selectedDrawing
                else { return }

                let resultScale = a / b

                // 2) локально сохраняем в CoreData
                viewModel.repository.updateDrawingScale(drawingId: drawing.id, scale: resultScale)
                // обновляем struct для отправки
                drawing.scale = resultScale
                selectedDrawing?.scale = resultScale

                Task {
                    // 3) отправляем НА СЕРВЕР уже обновлённый Drawing
                    let serverResult = await viewModel.sendRepository.updateDrawingOnServer(drawing: drawing)
                    if serverResult != .success {
                        print("❗️Ошибка отправки масштаба: \(serverResult)")
                    }

                    // 4) открываем PDF
                    do {
                        let fileURL = try await viewModel.prepareDrawingFile(drawing)
                        await MainActor.run {
                            selectedDrawing?.filePath = fileURL.path
                            // скрываем input (на случай если он был открыт)
                            showScaleInput = false
                            // 3) переходим в PDFViewer
                            navigateToPDF = true
                        }
                    } catch {
                        print("Не удалось загрузить чертёж:", error)
                    }
                }

          }
        }
    }
}

