import SwiftUI
import Combine

struct CreateProjectView: View {
    @ObservedObject var viewModel: CreateProjectViewModel
    @Environment(\.dismiss) var dismiss  // Для возврата к предыдущему экрану
    @State private var showError: Bool = false // Флаг для отображения ошибки
    @State private var showPhotoLoader = false
    @State private var showCamera = false
    @State private var showLoadFile = false
    @State private var showActionSheet = false // Показывать меню выбора

    var body: some View {
        VStack {
            TextField("Название проекта", text: $viewModel.uiState.projectName)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
                .padding()
            
            // Кнопка для прикрепления обложки
            Button(action: {
                showActionSheet = true
            }) {
                Text("Прикрепите обложку")
                    .font(.headline)
                    .padding()
                    .frame(width: 250, height: 60)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
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
            
            // Предпросмотр выбранного изображения (обложки)
            if let image = viewModel.uiState.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
            }
            
            Button(action: {
                viewModel.saveProject() // Сохранение проекта
                showError = !viewModel.uiState.isValidProjectName || !viewModel.uiState.isNotRepeatProjectName
                if !showError {
                    dismiss()
                }
            }) {
                Text("Сохранить")
                    .font(.headline)
                    .padding()
                    .frame(width: 250, height: 60)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
            }
            .padding()
        }
        .padding()
        .toast(isPresented: $showError, message: viewModel.errorMessage)
        .sheet(isPresented: $showPhotoLoader) {
            // Передаем binding для изображения обложки
            PhotoLoader(selectedImage: viewModel.coverImageBinding)
        }
        .sheet(isPresented: $showLoadFile) {
            // Передаем binding для изображения обложки
            LoadFile(selectedImage: viewModel.coverImageBinding, showError: $showError)
        }
        .fullScreenCover(isPresented: $showCamera) {
            // Передаем binding для изображения обложки
            TakePhoto(selectedImage: viewModel.coverImageBinding)
        }
    }
}

// Пример Toast-модификатора
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
                        .animation(.easeInOut(duration: 0.5), value: isPresented.wrappedValue)
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
