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
            
            Button(action: {
                viewModel.saveProject(name: projectName)
                if viewModel.errorMessage == nil {
                    dismiss() // Возвращаемся на предыдущий экран только если ошибки нет
                } else {
                    showError = true // Показываем уведомление, если ошибка
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
        .toast(isPresented: $showError, message: viewModel.errorMessage ?? "")
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
