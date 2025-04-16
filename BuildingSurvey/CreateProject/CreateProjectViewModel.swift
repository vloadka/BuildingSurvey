import SwiftUI
import Combine

// Состояние UI для создания проекта, теперь с обложкой проекта
struct AddProjectUiState {
    var projectName: String = ""               // Название проекта
    var isValidProjectName: Bool = true        // Флаг валидности имени проекта
    var isNotRepeatProjectName: Bool = true    // Флаг уникальности имени проекта
    var coverImage: UIImage? = nil             // Обложка проекта (изображение)
}

// ViewModel для создания проекта
class CreateProjectViewModel: ObservableObject {
    private var repository: GeneralRepository // Репозиторий для работы с проектами
    private var sendRepository: SendRepository
    
    @Published var uiState = AddProjectUiState() // Состояние UI
    @Published var activeProjects: [Project] = [] // Список активных проектов
    @Published var showToast: Bool = false        // Флаг для отображения уведомления
    
    private var cancellables = Set<AnyCancellable>() // Хранилище подписок для Combine
    
    init(repository: GeneralRepository) {
        self.repository = repository
        self.sendRepository = SendRepository(
            apiService: ApiService.shared,
            generalRepository: repository,
            customWorkManager: DummyCustomWorkManager()
        )
        loadActiveProjects() // Загружаем локальные проекты при инициализации
    }
    
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
    
    // Метод для сохранения проекта с явной передачей актуального токена
    func saveProject() {
        uiState.isValidProjectName = !uiState.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        uiState.isNotRepeatProjectName = !activeProjects.contains { $0.name == uiState.projectName }
        
        if uiState.isValidProjectName && uiState.isNotRepeatProjectName {
            let coverData = uiState.coverImage?.pngData()
            Task {
                // Убираем получение токена для передачи, так как метод createProjectOnServer сам его получает.
                print("DEBUG [CreateProjectViewModel] Создаем проект с именем: \(uiState.projectName)")
                let project = Project(name: uiState.projectName, coverImageData: coverData)
                // Вызов без параметра token
                let (result, serverProjectId) = await sendRepository.createProjectOnServer(project: project, coverImageData: coverData)
                DispatchQueue.main.async {
                    if result == .success {
                        // Сохраняем новый проект локально сразу, не очищая список
//                        self.repository.addProject(name: self.uiState.projectName, servId: serverProjectId, coverImageData: coverData)
                        self.repository.addProject(name: self.uiState.projectName, servId: Int(serverProjectId), coverImageData: coverData)
                        self.uiState = AddProjectUiState()
                    } else {
                        self.showToast = true
                    }
                }
            }
        } else {
            showToast = true
        }
    }


    
    // Метод для загрузки активных проектов (локально)
    func loadActiveProjects() {
        repository.projectsListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] projects in
                self?.activeProjects = projects
            }
            .store(in: &cancellables)
    }
    
    // Метод для установки обложки проекта
    func setCoverImage(_ image: UIImage) {
        uiState.coverImage = image
    }
    
    // Привязка для обложки проекта, если требуется использовать Binding
    var coverImageBinding: Binding<UIImage?> {
        Binding<UIImage?>(
            get: { self.uiState.coverImage },
            set: { self.uiState.coverImage = $0 }
        )
    }
}
