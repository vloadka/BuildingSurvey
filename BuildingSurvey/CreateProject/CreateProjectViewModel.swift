import SwiftUI
import Combine

// Структура состояния UI для хранения информации о проекте
struct AddProjectUiState {
    var projectName: String = "" // Название проекта
    var isValidProjectName: Bool = true // Флаг валидности имени проекта
    var isNotRepeatProjectName: Bool = true // Флаг уникальности имени проекта
    var currentPhotoPath: String = "" // Хранение пути к файлу обложки
}

// ViewModel для управления логикой создания проекта
class CreateProjectViewModel: ObservableObject {
    private var repository: GeneralRepository // Репозиторий для работы с проектами
    
    @Published var uiState = AddProjectUiState() // Состояние UI
    @Published var activeProjects: [Project] = [] // Список активных проектов
    @Published var showToast: Bool = false // Флаг для отображения уведомления
    @Published var projectFilePath: String = "" // Путь к файлу обложки проекта
    
    private var cancellables = Set<AnyCancellable>() // Хранилище подписок для Combine
    
    init(repository: GeneralRepository) {
        self.repository = repository
        self.loadActiveProjects() // Загружаем список активных проектов при инициализации
    }
    
    // Метод для обновления названия проекта
    func updateProjectName(_ name: String) {
        uiState.projectName = name
    }
    
    var errorMessage: String {
        if !uiState.isValidProjectName {
            return "Имя проекта не должно быть пустым."
        } else if !uiState.isNotRepeatProjectName {
            return "Проект с таким именем уже существует."
        }
        return "Не удалось загрузить. Выберите другое изображение"
    }
    
    func saveProject() {
           uiState.isValidProjectName = !uiState.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
           uiState.isNotRepeatProjectName = !activeProjects.contains { $0.name == uiState.projectName }

           if uiState.isValidProjectName && uiState.isNotRepeatProjectName {
               repository.addProject(
                   name: uiState.projectName,
                   projectFilePath: uiState.currentPhotoPath
               )
               loadActiveProjects()
           } else {
               showToast = true
           }
       }
        
        // Метод для загрузки активных проектов (isDeleted == 0)
        func loadActiveProjects() {
            repository.projectsListPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] projects in
                    self?.activeProjects = projects
                }
                .store(in: &cancellables)
        }
    
    // Метод для установки пути к файлу обложки
    func setProjectFilePath(_ path: String) {
        projectFilePath = path
    }
    
    // Преобразование String → String?
        var currentPhotoPathBinding: Binding<String?> {
            Binding<String?>(
                get: { self.uiState.currentPhotoPath },
                set: { self.uiState.currentPhotoPath = $0 ?? "" }
            )
        }
}
