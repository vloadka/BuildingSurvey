//
//  SendRepository.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 06.04.2025.
//

import Foundation

// Перечисления статусов ответа
enum DefaultResponse: Equatable {
    case success
    case noSuchElement
    case retry
    case internetError
}

enum RegisterResponse {
    case success
    case emailUnique
    case internetError
}

enum LoginResponse {
    case success
    case inputDataError
    case internetError
}


struct DummyCustomWorkManager: CustomWorkManager { }


protocol GeneralRepositoryInterface { }
protocol CustomWorkManager { }

// Тип загрузки данных – можно расширять по необходимости
enum DataLoadStep {
    case projects
    // другие шаги, если нужны
}

// Структура ответа от сервера для списка проектов
struct GetProjectsResponse: Decodable {
    let content: [ProjectOnServer]
    let last: Bool
}

// Модель проекта с сервера
struct ProjectOnServer: Decodable {
//    let id: String
    let id: Int
    let name: String
}

class SendRepository {
    private var jwtToken: String = ""
    private let outputDir: URL?
    
    let apiService: ApiService
    let generalRepository: GeneralRepository
    let customWorkManager: CustomWorkManager
    let dataStoreManager = DataStoreManager.shared
    
    
    init(apiService: ApiService,
         generalRepository: GeneralRepository,
         customWorkManager: CustomWorkManager) {
        self.apiService = apiService
        self.generalRepository = generalRepository
        self.customWorkManager = customWorkManager
        self.outputDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private func getJwtCookie() async -> String {
        let token = await DataStoreManager.shared.getJwtToken()
        return "jwt=\(token)"
    }
    
    private func handleResponse(_ response: HTTPURLResponse) async -> DefaultResponse {
        if (200...299).contains(response.statusCode) {
            return .success
        } else if response.statusCode == 409 {
            return .noSuchElement
        } else if response.statusCode == 401 {
            let refreshResult = await refresh()
            return (refreshResult == .success) ? .retry : refreshResult
        } else {
            return .internetError
        }
    }
    
    private func refresh() async -> DefaultResponse {
        do {
            let refreshToken = await dataStoreManager.getRefreshToken()
            let cookieHeader = "refresh=\(refreshToken)"
            let (_, response) = try await apiService.refresh(token: cookieHeader)
            
            if response.statusCode == 401 {
                return .internetError
            }
            
            if (200...299).contains(response.statusCode) {
                if let setCookie = response.allHeaderFields["Set-Cookie"] as? String {
                    let trimmed = setCookie.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let jwtRange = trimmed.range(of: "jwt=") {
                        let afterJwt = trimmed[jwtRange.upperBound...]
                        let jwt = afterJwt.split(separator: ";").first.map(String.init) ?? ""
                        if jwt.isEmpty {
                            return .internetError
                        } else {
                            self.jwtToken = jwt
                            return .success
                        }
                    } else {
                        return .internetError
                    }
                } else {
                    return .internetError
                }
            } else {
                return .internetError
            }
        } catch {
            return .internetError
        }
    }
    
    // Пример метода регистрации пользователя.
    func registerNewUser(user: UserForSignUp) async -> RegisterResponse {
        do {
            let (_, httpResponse) = try await apiService.registerNewUser(user: user)
            if (200...299).contains(httpResponse.statusCode) {
                return .success
            } else if httpResponse.statusCode == 409 {
                return .emailUnique
            } else {
                return .internetError
            }
        } catch {
            return .internetError
        }
    }
    
    // Метод логина пользователя с обработкой cookies (jwt и refresh‑token).
    func login(user: UserForSignIn) async -> LoginResponse {
        print("DEBUG: Начало метода login для пользователя: \(user.email)")
        do {
            let (data, httpResponse) = try await apiService.login(user: user)
            print("DEBUG: Ответ на login получен, статус HTTP: \(httpResponse.statusCode)")
            
            let headerFields = httpResponse.allHeaderFields as? [String: String] ?? [:]
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: apiService.baseURL)
            
            var foundJwt = false
            var foundRefresh = false
            
            for cookie in cookies {
                print("DEBUG: Обнаружен cookie: \(cookie.name) = \(cookie.value)")
                if cookie.name == "jwt" {
                    self.jwtToken = cookie.value
                    foundJwt = true
                    print("DEBUG: JWT токен сохранён: \(cookie.value)")
                    await dataStoreManager.updateJwtToken(token: cookie.value)
                } else if cookie.name == "refresh" {
                    await dataStoreManager.updateRefreshToken(refreshToken: cookie.value)
                    foundRefresh = true
                    print("DEBUG: refresh токен обновлён: \(cookie.value)")
                }
            }
            
            if !foundJwt {
                print("DEBUG: Отсутствует JWT токен")
                return .internetError
            }
            // Если сервер возвращает только JWT, можно указать, что refresh-токена может не быть.
            if !foundRefresh {
                print("DEBUG: refresh токен не получен. Если это допустимо, считаем, что логин успешный.")
                // При желании можно установить foundRefresh = true или, например, сохранить пустое значение.
                // foundRefresh = true
            }
            
            print("DEBUG: Завершение login, JWT найден: \(foundJwt), refresh найден: \(foundRefresh)")
            return (200...299).contains(httpResponse.statusCode) ? .success : .inputDataError
        } catch {
            print("DEBUG: Ошибка при выполнении метода login: \(error)")
            return .internetError
        }
    }
    
    
    func changeUserPassword(oldPassword: String, newPassword: String) async -> DefaultResponse {
        do {
            let jwtCookie = await getJwtCookie()
            let (_, httpResponse) = try await apiService.changeUserPassword(
                token: jwtCookie,
                changeUserPassword: ChangeUserPassword(oldPassword: oldPassword, newPassword: newPassword)
            )
            let result = await handleResponse(httpResponse)
            if result == .retry {
                return await changeUserPassword(oldPassword: oldPassword, newPassword: newPassword)
            } else {
                return result
            }
        } catch {
            return .internetError
        }
    }
    
    func sendAvatar(fileURL: URL) async -> DefaultResponse {
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let jwtCookie = await getJwtCookie()
            let (_, httpResponse) = try await apiService.sendAvatar(
                token: jwtCookie,
                fileData: fileData,
                fileName: fileName
            )
            
            let result = await handleResponse(httpResponse)
            if result == .retry {
                return await sendAvatar(fileURL: fileURL)
            } else {
                return result
            }
        } catch {
            return .internetError
        }
    }
    
    private func createMultipartBody(fileURL: URL, mimeType: String) throws -> (data: Data, boundary: String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let fileName = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return (data: body, boundary: boundary)
    }
    
    func updateUserData(user: UserData) async -> DefaultResponse {
        do {
            let jwtCookie = await getJwtCookie()
            let (_, httpResponse) = try await apiService.updateUserData(
                token: jwtCookie,
                userData: user
            )
            let result = await handleResponse(httpResponse)
            if result == .retry {
                return await updateUserData(user: user)
            } else {
                return result
            }
        } catch {
            return .internetError
        }
    }
    
    // MARK: - Методы работы с проектами на сервере
    
    // Предполагаем, что InspectionIdResponse определён как:
    struct InspectionIdResponse: Decodable {
        let id: String
    }
    
    // Создаёт пустой проект на сервере и возвращает пару: (статус, inspectionId)
    func createEmptyProjectOnServer() async -> (DefaultResponse, String) {
        do {
            let jwtCookie = await getJwtCookie()
            let (inspectionResponse, response) = try await apiService.createEmptyProject(token: jwtCookie)
            
            let result = await handleResponse(response)
            if result == .retry {
                return await createEmptyProjectOnServer()
            } else {
                return (result, inspectionResponse.id)
            }
        } catch {
            return (.internetError, "")
        }
    }
    
    func addProjectNameOnServer(projectName: String, serverProjectId: String) async -> DefaultResponse {
        do {
            let projectInfo = ProjectInfo(name: projectName)
            let jwtCookie = await getJwtCookie()
            let (_, response) = try await apiService.addNameProject(
                token: jwtCookie,
                id: serverProjectId,
                projectInfo: projectInfo
            )
            
            let result = await handleResponse(response)
            if result == .noSuchElement { return .success }
            if result == .retry {
                return await addProjectNameOnServer(projectName: projectName, serverProjectId: serverProjectId)
            }
            return result
        } catch {
            return .internetError
        }
    }
    
    // Новая функция создания проекта на сервере, возвращающая (DefaultResponse, serverProjectId)
    func createProjectOnServer(project: Project, coverImageData: Data?) async -> (DefaultResponse, String) {
        do {
            // Получаем актуальный jwt-токен непосредственно перед выполнением запроса
            let jwtCookie = await getJwtCookie()
            print("DEBUG [createProjectOnServer] Отправляем POST запрос на \(apiService.baseURL.appendingPathComponent("/api/v1/inspections")) с cookie: \(jwtCookie)")
            
            // 1. Создаем пустой проект на сервере
            let (inspectionResponse, httpResponseEmpty) = try await apiService.createEmptyProject(token: jwtCookie)
            let resultEmpty = await handleResponse(httpResponseEmpty)
            if resultEmpty != .success {
                print("DEBUG [createProjectOnServer] Ошибка при создании пустого проекта, результат: \(resultEmpty)")
                return (resultEmpty, "")
            }
            let serverProjectId = inspectionResponse.id
            print("DEBUG [createProjectOnServer] Получен serverProjectId: \(serverProjectId)")
            
            // Задержка для синхронизации с сервером
            try await Task.sleep(nanoseconds: 150_000_000)
            
            // 2. Отправляем имя проекта на сервер (PUT-запрос)
            let projectInfo = ProjectInfo(name: project.name)
            print("DEBUG [createProjectOnServer] Отправляем PUT запрос для добавления имени проекта: \(project.name)")
            let (_, httpResponseAddName) = try await apiService.addNameProject(token: jwtCookie, id: serverProjectId, projectInfo: projectInfo)
            let resultAddName = await handleResponse(httpResponseAddName)
            // Считаем статус .noSuchElement также успешным
            if resultAddName != .success && resultAddName != .noSuchElement {
                print("DEBUG [createProjectOnServer] Ошибка при добавлении имени проекта, результат: \(resultAddName)")
                return (resultAddName, serverProjectId)
            }
            print("DEBUG [createProjectOnServer] Имя проекта успешно добавлено")
            
            try await Task.sleep(nanoseconds: 150_000_000)
            
            // 3. Если передана обложка, отправляем файл на сервер (Multipart POST)
            if let imageData = coverImageData {
                print("DEBUG [createProjectOnServer] Отправляем POST запрос для загрузки обложки проекта (размер файла: \(imageData.count) байт)")
                let (_, httpResponseAvatar) = try await apiService.addAvatarProject(token: jwtCookie, id: serverProjectId, fileData: imageData, fileName: "cover.jpg")
                if !(200...299).contains(httpResponseAvatar.statusCode) {
                    print("DEBUG [createProjectOnServer] Ошибка при загрузке обложки, статус: \(httpResponseAvatar.statusCode)")
                    return (.internetError, serverProjectId)
                }
                print("DEBUG [createProjectOnServer] Обложка успешно добавлена")
            } else {
                print("DEBUG [createProjectOnServer] Обложка не передана")
            }
            
            return (.success, serverProjectId)
        } catch {
            print("DEBUG [createProjectOnServer] Исключение: \(error)")
            return (.internetError, "")
        }
    }
    
    // (При необходимости) метод удаления проекта на сервере
    func deleteProjectOnServer(servId: Int) async -> DefaultResponse {
        do {
            let jwtCookie = await getJwtCookie()
            let (_, response) = try await apiService.deleteProject(token: jwtCookie, id: String(servId))
            let result = await handleResponse(response)
            if result == .noSuchElement { return .success }
            if result == .retry { return await deleteProjectOnServer(servId: servId) }
            return result
        } catch {
            return .internetError
        }
    }
    
//        // Функция для загрузки проектов с сервера и сохранения их локально.
//        func getProjects(startStep: DataLoadStep) async -> DefaultResponse {
//            do {
//                // Удаляем очистку локального хранилища — это поведение как на Android.
//    
//                if startStep == .projects {
//                    let localProjects = generalRepository.currentProjects
//                    for project in localProjects {
//                        generalRepository.deleteProject(id: project.id)
//                    }
//                }
//    
//                var pageNum = 0
//                var isLastPage = false
//                var allProjects = [ProjectOnServer]()
//    
//                // Получаем актуальный токен прямо перед запросом
//                let token = await DataStoreManager.shared.getJwtToken()
//                let jwtCookie = "jwt=\(token)"
//    
//                while !isLastPage {
//                    try await Task.sleep(nanoseconds: 150_000_000)
//                    let (projectsResponse, response) = try await apiService.getProjects(token: jwtCookie, pageNum: pageNum, pageSize: 10)
//                    let result = await handleResponse(response)
//                    if result == .retry {
//                        return await getProjects(startStep: startStep)
//                    }
//                    if result != .success {
//                        return result
//                    }
//    
//                    allProjects.append(contentsOf: projectsResponse.content)
//                    isLastPage = projectsResponse.last
//                    pageNum += 1
//                }
//    
//                // Добавляем или обновляем каждый проект из ответа сервера.
//                for project in allProjects {
//                    try await Task.sleep(nanoseconds: 150_000_000)
//                    let (photoResult, photoPath) = await getProjectPhoto(project: project)
//                    var coverData: Data? = nil
//                    if photoResult == .success, !photoPath.isEmpty, let data = try? Data(contentsOf: URL(fileURLWithPath: photoPath)) {
//                        coverData = data
//                    } else {
//                        print("DEBUG [getProjects] Не удалось получить обложку для проекта: \(project.name)")
//                    }
//                    // Заменяем или добавляем проект, если его ещё нет.
//                    generalRepository.addProject(name: project.name, servId: project.id, coverImageData: coverData)
//    
//                    // Дополнительно загружаем аудио, если нужно.
//                    try await Task.sleep(nanoseconds: 150_000_000)
//                    let (audioResult, audioPath) = await getAudioProject(project: project)
//                    if audioResult == .success && !audioPath.isEmpty {
//                        if let audioData = try? Data(contentsOf: URL(fileURLWithPath: audioPath)) {
//                            generalRepository.saveAudio(
//                                forProject: Project(name: project.name, coverImageData: coverData),
//                                audioData: audioData,
//                                timestamp: Date(),
//                                drawingName: "Audio"
//                            )
//                        }
//                    } else {
//                        print("DEBUG [getProjects] Аудио для проекта \(project.name) не получено или отсутствует.")
//                    }
//                }
//    
//                return .success
//            } catch {
//                return .internetError
//            }
//        }
//
//
//    // Функция для загрузки фото проекта с сервера.
//    func getProjectPhoto(project: ProjectOnServer) async -> (DefaultResponse, String) {
//        do {
//            let jwtCookie = await getJwtCookie()
//            let (data, response) = try await apiService.getProjectPhoto(token: jwtCookie, id: project.id)
//
//            let result = await handleResponse(response)
//            if result == .retry {
//                return await getProjectPhoto(project: project)
//            }
//            if result != .success {
//                return (result, "")
//            }
//            // Если данные отсутствуют, возвращаем ошибку
//            if data.isEmpty {
//                return (.internetError, "")
//            }
//            
//            // Пытаемся извлечь заголовок Content-Disposition
//            let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String ?? ""
//            var savedFilePath: String?
//            
//            if contentDisposition.isEmpty {
//                // Если заголовка нет, сохраняем данные с принудительным расширением "jpg"
//                savedFilePath = saveResponseToFile(
//                    responseBody: data,
//                    contentDisposition: nil,
//                    name: "\(UUID().uuidString)_project",
//                    forcedExtension: "jpg"
//                )
//            } else {
//                savedFilePath = saveResponseToFile(
//                    responseBody: data,
//                    contentDisposition: contentDisposition,
//                    name: "\(UUID().uuidString)_project"
//                )
//            }
//            
//            guard let path = savedFilePath, !path.isEmpty else {
//                return (.internetError, "")
//            }
//            return (.success, path)
//        } catch {
//            return (.internetError, "")
//        }
//    }
    
    func getProjects(startStep: DataLoadStep) async -> DefaultResponse {
        do {
            // Если требуется очистить локальное хранилище, удаляем все локальные проекты.
            if startStep == .projects {
                let localProjects = generalRepository.currentProjects
                for project in localProjects {
                    generalRepository.deleteProject(id: project.id)
                }
            }
            
            var pageNum = 0
            var isLastPage = false
            var allProjects = [ProjectOnServer]()
            
            // Получаем актуальный jwt-токен и формируем заголовок Cookie
            let token = await DataStoreManager.shared.getJwtToken()
            let jwtCookie = "jwt=\(token)"
            
            // Пошагово загружаем страницы с проектами
            while !isLastPage {
                try await Task.sleep(nanoseconds: 150_000_000)
                let (projectsResponse, response) = try await apiService.getProjects(token: jwtCookie, pageNum: pageNum, pageSize: 10)
                let result = await handleResponse(response)
                if result == .retry {
                    return await getProjects(startStep: startStep)
                }
                if result != .success {
                    return result
                }
                allProjects.append(contentsOf: projectsResponse.content)
                isLastPage = projectsResponse.last
                pageNum += 1
            }
            
            // Для каждого проекта загружаем обложку и аудио, если они присутствуют
            for project in allProjects {
                try await Task.sleep(nanoseconds: 150_000_000)
                let (photoResult, photoPath) = await getProjectPhoto(project: project)
                var coverData: Data? = nil
                if photoResult == .success, !photoPath.isEmpty,
                   let data = try? Data(contentsOf: URL(fileURLWithPath: photoPath)) {
                    coverData = data
                } else {
                    print("DEBUG [getProjects] Не удалось получить обложку для проекта: \(project.name)")
                }
                generalRepository.addProject(name: project.name, servId: project.id, coverImageData: coverData)
                
                try await Task.sleep(nanoseconds: 150_000_000)
                let (audioResult, audioPath) = await getAudioProject(project: project)
                if audioResult == .success && !audioPath.isEmpty,
                   let audioData = try? Data(contentsOf: URL(fileURLWithPath: audioPath)) {
                    generalRepository.saveAudio(
                        forProject: Project(name: project.name, coverImageData: coverData),
                        audioData: audioData,
                        timestamp: Date(),
                        drawingName: "Audio"
                    )
                } else {
                    print("DEBUG [getProjects] Аудио для проекта \(project.name) не получено или отсутствует.")
                }
            }
            
            return .success
        } catch {
            return .internetError
        }
    }

    // Модифицированный метод для загрузки фото проекта.
    // Если данные пусты, возвращаем успех с пустой строкой, а не ошибку.
    func getProjectPhoto(project: ProjectOnServer) async -> (DefaultResponse, String) {
        do {
            let jwtCookie = await getJwtCookie()
            let (data, response) = try await apiService.getProjectPhoto(token: jwtCookie, id: project.id)
            let result = await handleResponse(response)
            if result == .retry {
                return await getProjectPhoto(project: project)
            }
            if result != .success {
                return (result, "")
            }
            // Если данные отсутствуют – считаем, что обложки нет, но это не ошибка
            if data.isEmpty {
                return (.success, "")
            }
            let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String ?? ""
            var savedFilePath: String?
            if contentDisposition.isEmpty {
                savedFilePath = saveResponseToFile(
                    responseBody: data,
                    contentDisposition: nil,
                    name: "\(UUID().uuidString)_project",
                    forcedExtension: "jpg"
                )
            } else {
                savedFilePath = saveResponseToFile(
                    responseBody: data,
                    contentDisposition: contentDisposition,
                    name: "\(UUID().uuidString)_project"
                )
            }
            guard let path = savedFilePath, !path.isEmpty else {
                return (.internetError, "")
            }
            return (.success, path)
        } catch {
            return (.internetError, "")
        }
    }

    
    // Функция для загрузки аудио проекта с сервера.
    func getAudioProject(project: ProjectOnServer) async -> (DefaultResponse, String) {
        do {
            let jwtCookie = await getJwtCookie()
            let (data, response) = try await apiService.getAudioProject(
                token: jwtCookie,
                id: project.id
            )

            let result = await handleResponse(response)
            if result == .noSuchElement {
                return (.success, "")
            }
            if result == .retry {
                return await getAudioProject(project: project)
            }
            if result != .success {
                return (result, "")
            }
            if data.isEmpty {
                return (.internetError, "")
            }
            let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String ?? ""
            guard let savedFilePath = saveResponseToFile(
                responseBody: data,
                contentDisposition: contentDisposition,
                name: "\(UUID().uuidString)_audio"
            ) else {
                return (.internetError, "")
            }
            return (.success, savedFilePath)
        } catch {
            return (.internetError, "")
        }
    }

    // Функция для сохранения данных ответа в файл и возврата пути к нему
    func saveResponseToFile(responseBody: Data, contentDisposition: String?, name: String, forcedExtension: String? = nil) -> String? {
        var fileExtension: String
        if let forced = forcedExtension {
            fileExtension = forced
        } else {
            // Используем регулярное выражение для извлечения имени файла из Content-Disposition
            guard let cd = contentDisposition else { return nil }
            let pattern = "filename=\"?([^\";]+)\"?"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
            let nsString = cd as NSString
            let results = regex.matches(in: cd, options: [], range: NSRange(location: 0, length: nsString.length))
            guard let match = results.first, match.numberOfRanges > 1 else { return nil }
            let fileName = nsString.substring(with: match.range(at: 1))
            // Извлекаем расширение после последней точки
            if let dotRange = fileName.range(of: ".", options: .backwards) {
                fileExtension = String(fileName[dotRange.upperBound...])
            } else {
                fileExtension = ""
            }
        }
        // Если расширение пустое и имя содержит "_audio", используем "mp4"
        if fileExtension.isEmpty {
            if name.contains("_audio") {
                fileExtension = "mp4"
            } else {
                return nil
            }
        }
        let newFileName = "\(name).\(fileExtension)"
        // outputDir – директория для сохранения файлов (устанавливается при инициализации SendRepository)
        guard let outputDir = outputDir else { return nil }
        let fileURL = outputDir.appendingPathComponent(newFileName)
        do {
            try responseBody.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }
    
    // Проверяет подтверждение email.
    // Если сервер возвращает статус retry, метод вызывается рекурсивно.
    func checkEmailConfirmation() async -> (DefaultResponse, Bool) {
        do {
            let jwtCookie = await getJwtCookie()
            let (verifiedResponse, response) = try await apiService.checkEmailConfirmation(token: jwtCookie)

            let result = await handleResponse(response)
            if result == .retry {
                return await checkEmailConfirmation()
            } else if result == .success {
                return (.success, verifiedResponse.verified)
            } else {
                return (result, false)
            }
        } catch {
            return (.internetError, false)
        }
    }
}
