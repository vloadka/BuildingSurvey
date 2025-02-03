import SwiftUI

struct CreateProjectView: View {
    @State private var projectName: String = ""
    @ObservedObject var viewModel: CreateProjectViewModel
    @Environment(\.dismiss) var dismiss  // Используется для возврата к предыдущему экрану
    @State private var showError: Bool = false // Переменная для отображения ошибки
    @State private var showPhotoLoader = false
    @State private var showCamera = false
    @State private var showLoadFile = false
    @State private var selectedPhoto: UIImage?
    @State private var showActionSheet = false // Показывать меню выбора

    var body: some View {
        VStack {
            TextField("Название проекта", text: $viewModel.uiState.projectName)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.1)]), startPoint: .top, endPoint: .bottom)) // Градиентный фон
                .cornerRadius(10) // Скругленные углы
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5) // Тень для объема
                .padding()
            
            // Кнопка прикрепления обложки
                        Button(action: {
                            showActionSheet = true // Показываем меню выбора
                        }) {
                            Text("Прикрепите обложку")
                                .font(.headline)
                                .padding()
                                .frame(width: 250, height: 60) // Увеличили размер кнопки
                                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)) // Градиентный фон
                                .foregroundColor(.white)
                                .cornerRadius(15) // Более скругленные углы
                                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5) // Тень для объема
                        }
                        .padding()
                        .actionSheet(isPresented: $showActionSheet) {
                            ActionSheet(
                                title: Text("Выберите источник"),
                                buttons: [
                                    .default(Text("Выбрать из фото")) { showPhotoLoader = true },
                                    .default(Text("Выбрать из файлов")) { showLoadFile = true },
                                    .default(Text("Сделать снимок")) { showCamera = true },
                                    .cancel()
                                ]
                            )
                        }

                        // Предпросмотр выбранного изображения
                        if let image = selectedPhoto {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                        }
                        
            
            Button(action: {
                viewModel.saveProject() //Сохранение проекта
                showError = !viewModel.uiState.isValidProjectName || !viewModel.uiState.isNotRepeatProjectName   //Флаг ошибки
                if !showError {
                    dismiss()
                }
            }) {
                Text("Сохранить")
                    .font(.headline)
                    .padding()
                    .frame(width: 250, height: 60) // Увеличили размер кнопки
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)) // Градиентный фон
                    .foregroundColor(.white)
                    .cornerRadius(15) // Более скругленные углы
                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5) // Тень для объема
            }
            .padding()
        }
        .padding()
        .toast(isPresented: $showError, message: viewModel.errorMessage)
        .sheet(isPresented: $showPhotoLoader) {
            PhotoLoader(selectedImage: $selectedPhoto, selectedPhotoPath: viewModel.currentPhotoPathBinding)
        }
        .sheet(isPresented: $showLoadFile) {
            LoadFile(selectedImage: $selectedPhoto, selectedPhotoPath: viewModel.currentPhotoPathBinding)
        }
        .fullScreenCover(isPresented: $showCamera) {
            TakePhoto(selectedImage: $selectedPhoto, selectedPhotoPath: viewModel.currentPhotoPathBinding)
        }


    }
}

// Пример простой Toast-функции
extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                VStack {
                    Spacer()
                    Text(message)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.move(edge: .bottom))
                        .animation(.easeInOut(duration: 0.5))
                }
                .padding()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isPresented.wrappedValue = false
                    }
                }
            }
        }
    }
}
