import SwiftUI

class CreateProjectViewModel: ObservableObject {
    private var repository: GeneralRepository
    
    @Published var errorMessage: String? // Сообщение об ошибке
    @Published var showToast: Bool = false // Для отображения уведомления
    @Published var activeProjects: [Project] = [] // Список активных проектов

    init(repository: GeneralRepository) {
        self.repository = repository
        self.loadActiveProjects() // Загружаем активные проекты при инициализации
    }
    
    // Метод для сохранения проекта
    func saveProject(name: String) {
        // Проверка, что имя не пустое
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Имя проекта не должно быть пустым."
            showToast = true // Показываем уведомление
            return
        }
        
        // Проверка, что имя не повторяется
        let existingProjectNames = repository.getProjectNames()
        if existingProjectNames.contains(name) {
            errorMessage = "Проект с таким именем уже существует."
            showToast = true // Показываем уведомление
            return
        }
        
        // Если все проверки прошли успешно, сохраняем проект
        repository.addProject(name: name, isDeleted: 0) // Добавляем проект с isDeleted = 0
        loadActiveProjects() // Обновляем список активных проектов
        errorMessage = nil // Очищаем сообщение об ошибке
    }
    
    
    // Метод для загрузки активных проектов (isDeleted == 0)
    func loadActiveProjects() {
        // Получаем активные проекты из репозитория
        activeProjects = repository.getActiveProjects() // Сохраняем проекты, а не их имена
    }

    // Метод для "удаления" проекта, просто устанавливаем isDeleted = 1
    func deleteProject(_ project: Project) {
        repository.updateProject(id: project.id, isDeleted: 1)
        loadActiveProjects()
    }

}
