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

// Протоколы для зависимостей
protocol DataStoreManager {
    func updateRefreshToken(token: String) async
}

// Фиктивные реализации для зависимостей SendRepository
struct DummyDataStoreManager: DataStoreManager {
    func updateRefreshToken(token: String) async { }
}

struct DummyCustomWorkManager: CustomWorkManager { }

// Обеспечиваем соответствие GeneralRepository протоколу GeneralRepositoryInterface
extension GeneralRepository: GeneralRepositoryInterface { }

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
    let id: String
    let name: String
}

class SendRepository {
    private var jwtToken: String = ""
    private let outputDir: URL?
    
    let apiService: ApiService
    let generalRepository: GeneralRepository
    let dataStoreManager: DataStoreManager
    let customWorkManager: CustomWorkManager
    
    init(apiService: ApiService,
         generalRepository: GeneralRepository,
         dataStoreManager: DataStoreManager,
         customWorkManager: CustomWorkManager) {
        self.apiService = apiService
        self.generalRepository = generalRepository
        self.dataStoreManager = dataStoreManager
        self.customWorkManager = customWorkManager
        self.outputDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // Обработка ответа с проверкой кода статуса.
    // Если код 401 – вызывается метод refresh (здесь представлен как заглушка).
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
    
    // Заглушка для обновления токена – реализуйте логику по необходимости.
    private func refresh() async -> DefaultResponse {
        // Здесь должна быть логика обновления токена.
        return .internetError
    }
    
    // MARK: - Методы работы с API
    
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
    
    func login(user: UserForSignIn) async -> LoginResponse {
        do {
            print("Выполняется login через ApiService...")

            let (_, httpResponse) = try await apiService.login(user: user)

            print("HTTP статус login:", httpResponse.statusCode)
            print("Заголовки ответа:", httpResponse.allHeaderFields)

            let headerFields = httpResponse.allHeaderFields as? [String: String] ?? [:]
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: apiService.baseURL)

            var foundJwt = false
            var foundRefresh = false
            for cookie in cookies {
                print("🔍 Cookie: \(cookie.name) = \(cookie.value)")
                if cookie.name == "jwt" {
                    self.jwtToken = cookie.value
                    foundJwt = true
                } else if cookie.name == "refresh" {
                    await dataStoreManager.updateRefreshToken(token: cookie.value)
                    foundRefresh = true
                }
            }

            if !foundJwt || !foundRefresh {
                print("Не найден jwt или refresh-token")
                return .internetError
            }

            return (200...299).contains(httpResponse.statusCode) ? .success : .inputDataError

        } catch {
            print("Ошибка login запроса:", error)
            return .internetError
        }
    }

    
    func changeUserPassword(oldPassword: String, newPassword: String) async -> DefaultResponse {
        do {
            let (_, httpResponse) = try await apiService.changeUserPassword(
                token: "jwt=\(jwtToken)",
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
            let (_, httpResponse) = try await apiService.sendAvatar(
                token: "jwt=\(jwtToken)",
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
            let (_, httpResponse) = try await apiService.updateUserData(
                token: "jwt=\(jwtToken)",
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
            let (inspectionResponse, response) = try await apiService.createEmptyProject(token: "jwt=\(jwtToken)")
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
   
   // Отправляет на сервер имя проекта, используя серверный идентификатор
   func addProjectNameOnServer(projectName: String, serverProjectId: String) async -> DefaultResponse {
       do {
           let projectInfo = ProjectInfo(name: projectName)
           let (_, response) = try await apiService.addNameProject(
               token: "jwt=\(jwtToken)",
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
   
   // Создает проект на сервере: получает серверный id, отправляет имя и (при наличии) загружает обложку.
    func createProjectOnServer(project: Project, coverImageData: Data?) async -> DefaultResponse {
        do {
            let (emptyResult, serverProjectId) = await createEmptyProjectOnServer()
            if emptyResult != .success {
                return emptyResult
            }
            
            // Небольшая задержка, если требуется для синхронизации с сервером
            try await Task.sleep(nanoseconds: 150_000_000)
            
            let addNameResult = await addProjectNameOnServer(projectName: project.name, serverProjectId: serverProjectId)
            if addNameResult != .success {
                return .internetError
            }
            
            try await Task.sleep(nanoseconds: 150_000_000)
            
            if let imageData = coverImageData {
                let (_, avatarResponse) = try await apiService.addAvatarProject(
                    token: "jwt=\(jwtToken)",
                    id: serverProjectId,
                    fileData: imageData,
                    fileName: "cover.jpg"
                )
                if !(200...299).contains(avatarResponse.statusCode) {
                    return .internetError
                }
            }
            
            return .success
        } catch {
            return .internetError
        }
    }

   
   // (При необходимости) метод удаления проекта на сервере
   func deleteProjectOnServer(servId: String) async -> DefaultResponse {
       do {
           let (_, response) = try await apiService.deleteProject(token: "jwt=\(jwtToken)", id: servId)
           let result = await handleResponse(response)
           if result == .noSuchElement { return .success }
           if result == .retry { return await deleteProjectOnServer(servId: servId) }
           return result
       } catch {
           return .internetError
       }
   }
    
    // Функция для загрузки проектов с сервера с использованием функций generalRepository
    func getProjects(startStep: DataLoadStep) async -> DefaultResponse {
        do {
            // Если загрузка начинается с проектов – очищаем локальное хранилище, если такая функция реализована
            // Например: generalRepository.deleteAllProjects()
            // Если такого метода нет, можно перебрать проекты и удалить их по отдельности:
            // for project in generalRepository.allProjects { generalRepository.deleteProject(id: project.id) }
            
            var pageNum = 0
            var isLastPage = false
            var allProjects: [ProjectOnServer] = []
            
            // Пагинация: загружаем по 10 проектов за раз
            while !isLastPage {
                try await Task.sleep(nanoseconds: 150_000_000) // задержка 150 мс
                let (projectsResponse, response) = try await apiService.getProjects(
                    token: "jwt=\(jwtToken)",
                    pageNum: pageNum,
                    pageSize: 10
                )
                let result = await handleResponse(response)
                if result == DefaultResponse.retry {
                    return await getProjects(startStep: startStep)
                }
                if result != DefaultResponse.success {
                    return result
                }
                allProjects.append(contentsOf: projectsResponse.content)
                isLastPage = projectsResponse.last
                pageNum += 1
            }
            
            // Обрабатываем каждый проект: получаем фото и (при необходимости) аудио
            for project in allProjects {
                try await Task.sleep(nanoseconds: 150_000_000)
                let (photoResult, photoPath) = await getProjectPhoto(for: project)
                if photoResult != DefaultResponse.success {
                    return photoResult
                }
                
                // Загружаем данные обложки из файла, если путь не пустой
                var coverData: Data? = nil
                if !photoPath.isEmpty, let data = try? Data(contentsOf: URL(fileURLWithPath: photoPath)) {
                    coverData = data
                }
                // Сохраняем проект локально – метод addProject принимает name и coverImageData
                generalRepository.addProject(name: project.name, coverImageData: coverData)
                
                try await Task.sleep(nanoseconds: 150_000_000)
                let (audioResult, audioPath) = await getAudioProject(for: project)
                if audioResult == DefaultResponse.success && !audioPath.isEmpty {
                    if let audioData = try? Data(contentsOf: URL(fileURLWithPath: audioPath)) {
                        // Сохраняем аудио через функцию saveAudio
                        generalRepository.saveAudio(forProject: Project(name: project.name, coverImageData: coverData),
                                                    audioData: audioData,
                                                    timestamp: Date(),
                                                    drawingName: "Audio")
                    }
                } else if audioResult != DefaultResponse.success {
                    return audioResult
                }
            }
            
            return DefaultResponse.success
        } catch {
            return DefaultResponse.internetError
        }
    }

    // Функция для загрузки фото проекта с сервера
    func getProjectPhoto(for project: ProjectOnServer) async -> (DefaultResponse, String) {
        do {
            let (data, response) = try await apiService.getProjectPhoto(
                token: "jwt=\(jwtToken)",
                id: project.id
            )
            let result = await handleResponse(response)
            if result == .retry {
                return await getProjectPhoto(for: project)
            }
            if result != .success {
                return (result, "")
            }
            // Читаем заголовок Content-Disposition для определения имени файла
            if let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String,
               !contentDisposition.isEmpty {
                if let savedFilePath = saveResponseToFile(
                    responseBody: data,
                    contentDisposition: contentDisposition,
                    name: "\(UUID().uuidString)_project"
                ) {
                    return (.success, savedFilePath)
                } else {
                    return (.internetError, "")
                }
            } else {
                return (.success, "")
            }
        } catch {
            return (.internetError, "")
        }
    }
    
    // Функция для загрузки аудио для проекта с сервера
    func getAudioProject(for project: ProjectOnServer) async -> (DefaultResponse, String) {
        do {
            // Выполняем запрос к API для получения аудио проекта
            let (data, response) = try await apiService.getAudioProject(
                token: "jwt=\(jwtToken)",
                id: project.id
            )
            let result = await handleResponse(response)
            if result == .noSuchElement {
                return (.success, "")
            }
            if result == .retry {
                return await getAudioProject(for: project)
            }
            if result != .success {
                return (result, "")
            }
            // Проверяем наличие данных
            guard !data.isEmpty else {
                return (.internetError, "")
            }
            // Получаем заголовок Content-Disposition для извлечения расширения файла
            let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String
            // Сохраняем данные в файл и получаем путь
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
    
}
