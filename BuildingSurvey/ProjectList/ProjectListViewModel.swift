import SwiftUI
import Combine

// Модель состояния для управления состоянием проекта
struct ProjectListUiState {
    var projects: [Project] = []
}

class ProjectListViewModel: ObservableObject {
    @Published var uiState = ProjectListUiState()
    var repository: GeneralRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: GeneralRepository) {
        self.repository = repository
        
        repository.projectsListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] projects in
                self?.uiState.projects = projects
            }
            .store(in: &cancellables)
    }
    
    func deleteProject(id: UUID) {
        repository.deleteProject(id: id)
    }
    
    // Метод для загрузки обложки проекта по его id
    func loadCoverImage(for projectId: UUID) -> UIImage? {
        return repository.loadCoverImage(forProjectId: projectId)
    }
}
