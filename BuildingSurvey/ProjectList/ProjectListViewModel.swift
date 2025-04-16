import SwiftUI
import Combine

// Модель состояния для управления состоянием проектов
struct ProjectListUiState {
    var projects: [Project] = []
}

class ProjectListViewModel: ObservableObject {
    @Published var uiState = ProjectListUiState()
    var repository: GeneralRepository
    private var sendRepository: SendRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: GeneralRepository) {
        self.repository = repository
        self.sendRepository = SendRepository(
            apiService: ApiService.shared,
            generalRepository: repository,
            customWorkManager: DummyCustomWorkManager()
        )
        
        repository.projectsListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] projects in
                self?.uiState.projects = projects
            }
            .store(in: &cancellables)
        
        print("ProjectListViewModel: Инициализатор вызван. Перед вызовом loadProjectsFromServer().")
        loadProjectsFromServer()
    }
    
    func loadProjectsFromServer() {
        print("ProjectListViewModel: loadProjectsFromServer() вызван.")
        Task {
            let result = await sendRepository.getProjects(startStep: .projects)
            if result != .success {
                print("ProjectListViewModel: Ошибка при загрузке проектов с сервера. Результат: \(result)")
            } else {
                print("ProjectListViewModel: Проекты успешно загружены с сервера.")
            }
        }
    }
    
    func deleteProject(id: UUID) {
        Task {
            guard let project = repository.currentProjects.first(where: { $0.id == id }) else {
                print("ProjectListViewModel-deleteProject: проект не найден в локальном репозитории")
                return
            }
            
            guard let servId = project.servId else {
                       print("ProjectListViewModel-deleteProject: servId неизвестен")
                       return
                   }
            let result = await sendRepository.deleteProjectOnServer(servId: servId)
            switch result {
            case .success:
                repository.deleteProject(id: id)
                print("ProjectListViewModel-deleteProject: проект \(project.name) удалён")
                
            default:
                print("ProjectListViewModel-deleteProject: ошибка удаления на сервере — \(result)")
            }
        }
    }
    
    func loadCoverImage(for projectId: UUID) -> UIImage? {
        return repository.loadCoverImage(forProjectId: projectId)
    }
}
