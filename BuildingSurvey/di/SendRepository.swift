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

class SendRepository {
    private var jwtToken: String = ""
    private let outputDir: URL?
    
    let apiService: ApiService
    let generalRepository: GeneralRepositoryInterface
    let dataStoreManager: DataStoreManager
    let customWorkManager: CustomWorkManager
    
    init(apiService: ApiService,
         generalRepository: GeneralRepositoryInterface,
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
            let (_, httpResponse) = try await apiService.login(user: user)
            if (200...299).contains(httpResponse.statusCode) {
                let headerFields = httpResponse.allHeaderFields as? [String: String] ?? [:]
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: apiService.baseURL)
                var foundJwt = false
                var foundRefresh = false
                for cookie in cookies {
                    if cookie.name == "jwt" {
                        self.jwtToken = cookie.value
                        foundJwt = true
                    } else if cookie.name == "refresh" {
                        await dataStoreManager.updateRefreshToken(token: cookie.value)
                        foundRefresh = true
                    }
                }
                if !foundJwt || !foundRefresh {
                    return .internetError
                }
            }
            if (200...299).contains(httpResponse.statusCode) {
                return .success
            } else if httpResponse.statusCode == 401 {
                return .inputDataError
            } else {
                return .internetError
            }
        } catch {
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
}
