//
//  ApiService.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 06.04.2025.
//

import Foundation

// Модели для работы с API
struct UserForSignUp: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String    // Локальное название для фамилии
    let patronymic: String

    // Маппинг: lastName кодируется как "secondName"
    enum CodingKeys: String, CodingKey {
        case email, password, firstName, patronymic
        case lastName = "secondName"
    }
}

struct UserForSignIn: Codable {
    let email: String
    let password: String
    let secretToken: String
}


struct ChangeUserPassword: Codable {
    let oldPassword: String
    let newPassword: String
}

struct UserData: Codable {
    let firstName: String
    let lastName: String
    let patronymic: String
    let email: String
}

struct InspectionIdResponse: Codable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "inspectionId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Пытаемся декодировать как Int
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            // Иначе как String
            self.id = try container.decode(String.self, forKey: .id)
        }
    }
}


struct ProjectInfo: Codable {
    let name: String
    // Добавьте другие поля, если требуется
}

struct IdResponse: Codable {
    let id: String
}

struct UuidResponse: Codable {
    let uuid: String
}

struct TypeOfDefectBody: Codable {
    let type: String
    let description: String?
}

struct DefectBody: Codable {
    let defectType: String
    let severity: Int
    let description: String?
}

struct AxisBody: Codable {
    let axisName: String
    let value: Double
}

struct TextBody: Codable {
    let text: String
}

struct Verified: Codable {
    let verified: Bool
}

struct PlanOnServer: Codable {
    let id: Int64
    let name: String
    let scale: Double?
}

struct PlansResponse: Codable {
    let content: [PlanOnServer]
    let last: Bool
    
    enum CodingKeys: String, CodingKey {
        case content = "plans"
        case last
    }
    
    init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.content = try c.decode([PlanOnServer].self, forKey: .content)
            self.last = try c.decodeIfPresent(Bool.self, forKey: .last) ?? true
        }
}

class ApiService {
    static let shared = ApiService()
    let baseURL = URL(string: "http://192.168.1.189:8080")!
//    let baseURL = URL(string: "http://127.0.0.1:8080")!
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        configuration.httpAdditionalHeaders = ["User-Agent": "KsupointApp/1.0"]
        self.session = URLSession(configuration: configuration)
    }
    
    func registerNewUser(user: UserForSignUp) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/auth/sign-up")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(user)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    func login(user: UserForSignIn) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/auth/sign-in")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(user)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    func changeUserPassword(token: String, changeUserPassword: ChangeUserPassword) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/account/password")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(changeUserPassword)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    func updateUserData(token: String, userData: UserData) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/account/update-user")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(userData)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    func sendAvatar(token: String, fileData: Data, fileName: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/account/logo")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let mimeType = "image/jpeg" // или другой, если необходимо
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // POST /api/v1/inspections
    func createEmptyProject(token: String) async throws -> (InspectionIdResponse, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        print("DEBUG [createEmptyProject] Отправляем POST запрос на \(url) с токеном: \(token)")
        
        // Выполнение запроса без тела
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
             throw URLError(.badServerResponse)
        }
        print("DEBUG [createEmptyProject] Получен ответ с кодом: \(httpResponse.statusCode)")
        if let bodyString = String(data: data, encoding: .utf8) {
            print("DEBUG [createEmptyProject] Тело ответа: \(bodyString)")
        }
        print("DEBUG [createEmptyProject] Получен ответ с кодом: \(httpResponse.statusCode)")
        if !(200...299).contains(httpResponse.statusCode) {
             if let jsonString = String(data: data, encoding: .utf8) {
                 print("DEBUG [createEmptyProject] Response body: \(jsonString)")
             }
             throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(InspectionIdResponse.self, from: data)
        print("DEBUG [createEmptyProject] Декодированный объект: \(decoded)")
        return (decoded, httpResponse)
    }
    
    // PUT /api/v1/inspections/{id}
    func addNameProject(token: String, id: String, projectInfo: ProjectInfo) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let requestBody = try JSONEncoder().encode(projectInfo)
        print("[addNameProject] Отправляем PUT запрос на \(url.absoluteString) с телом: \(String(data: requestBody, encoding: .utf8) ?? "nil")")
        
        request.httpBody = requestBody
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[addNameProject] Неверный тип ответа")
            throw URLError(.badServerResponse)
        }
        print("[addNameProject] Получен ответ с кодом: \(httpResponse.statusCode)")
        
        return (data, httpResponse)
    }

    
    // Метод для отправки файла-обложки проекта на сервер по URL
    // Multipart POST /api/v1/inspections/{id}/main-photo
    func addAvatarProject(token: String, id: String, fileData: Data, fileName: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/main-photo")
        print("DEBUG: addAvatarProject - URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Устанавливаем заголовок Cookie с токеном
        request.setValue(token, forHTTPHeaderField: "Cookie")
        print("DEBUG: addAvatarProject - Token: \(token)")
        
        // Формирование multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        print("DEBUG: addAvatarProject - Boundary: \(boundary)")
        
        var body = Data()

        // Добавляем файл-обложку
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        print("DEBUG: addAvatarProject - Added file to body with name: \(fileName), file size: \(fileData.count) bytes")
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        print("DEBUG: addAvatarProject - Request body formed (size: \(body.count) bytes). Starting network request...")
        
        // Выполняем запрос
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("DEBUG: addAvatarProject - Response is not a HTTPURLResponse")
            throw URLError(.badServerResponse)
        }
        
        print("DEBUG: addAvatarProject - Received response with status code: \(httpResponse.statusCode)")
        return (data, httpResponse)
    }


        
    // DELETE /api/v1/inspections/{id}
    func deleteProject(token: String, id: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // Multipart POST /api/v1/inspections/{id}/plans?name=...&scale=...
    func addDrawing(token: String, id: String, name: String, scale: Double?, fileData: Data, fileName: String) async throws -> (IdResponse, HTTPURLResponse) {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "name", value: name)]
        if let scale = scale {
            queryItems.append(URLQueryItem(name: "scale", value: "\(scale)"))
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
//        let mimeType = "image/jpeg"
        let mimeType = "application/pdf"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("[ApiService.addDrawing] POST /inspections/\(id)/plans name=\(name) scale=\(String(describing: scale)) fileName=\(fileName)")
            
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(IdResponse.self, from: data)
        print("[ApiService.addDrawing] decoded id: \(decoded.id)")
        return (decoded, httpResponse)
    }
    
    // GET /api/v1/inspections/{id}/plans?pageNum=&pageSize=
    func getDrawings(token: String, id: String, pageNum: Int, pageSize: Int) async throws -> (PlansResponse, HTTPURLResponse) {
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "pageNum", value: "\(pageNum)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Cookie")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        print("DEBUG [getDrawings] body: \(String(data: data, encoding: .utf8) ?? "<‑не удалось прочитать>")")
        let decoded = try JSONDecoder().decode(PlansResponse.self, from: data)
        return (decoded, httpResponse)
    }
    
    // DELETE /api/v1/inspections/{id}/plans/{planId}
    func deleteDrawing(token: String, id: String, planId: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // PUT /api/v1/inspections/{id}/plans/{planId}?name=...&scale=...
    func updateDrawing(token: String, id: String, planId: String, name: String, scale: Double?) async throws -> (Data, HTTPURLResponse) {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "name", value: name)]
        if let scale = scale {
            queryItems.append(URLQueryItem(name: "scale", value: "\(scale)"))
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        print("[ApiService.updateDrawing] PUT \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
           if !(200...299).contains(httpResponse.statusCode) {
               let body = String(data: data, encoding: .utf8) ?? "<no body>"
               print("[ApiService.updateDrawing] ERROR status=\(httpResponse.statusCode), body: \(body)")
           }
        
        return (data, httpResponse)
    }

    // GET /api/v1/inspections/{id}/plans/{planId}/file
    func getDrawingFile(token: String, id: String, planId: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)/file")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
//    // GET /api/v1/inspections/{id}/plans/{planId}/file (или просто /plans/{planId})
//    func downloadDrawing(
//      token: String,
//      projectId: String,
//      planId: String
//    ) async throws -> (Data, HTTPURLResponse) {
//        let url = baseURL
//          .appendingPathComponent("/api/v1/inspections/\(projectId)/plans/\(planId)")
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue(token, forHTTPHeaderField: "Cookie")
//        let (data, response) = try await session.data(for: request)
//        guard let http = response as? HTTPURLResponse else {
//          throw URLError(.badServerResponse)
//        }
//        return (data, http)
//    }
    
    // POST /api/v1/inspections/{id}/type-defect
    func addTypeOfDefect(token: String, id: String, typeOfDefectBody: TypeOfDefectBody) async throws -> (UuidResponse, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/type-defect")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(typeOfDefectBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(UuidResponse.self, from: data)
        return (decoded, httpResponse)
    }
    
    // POST /api/v1/inspections/{id}/plans/{planId}
    func addDefect(token: String, id: String, planId: String, defectBody: DefectBody) async throws -> (UuidResponse, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(defectBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(UuidResponse.self, from: data)
        return (decoded, httpResponse)
    }
    
    // POST /api/v1/inspections/{id}/plans/{planId}/axis
    func addAxis(token: String, id: String, planId: String, axisBody: AxisBody) async throws -> (UuidResponse, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)/axis")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(axisBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(UuidResponse.self, from: data)
        return (decoded, httpResponse)
    }
    
    // DELETE /api/v1/inspections/{id}/plans/{planId}/axis/{uuid}
    func deleteAxis(token: String, id: String, planId: String, uuid: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)/axis/\(uuid)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // PUT /api/v1/inspections/{id}/plans/{planId}/axis/{uuid}
    func updateAxis(token: String, id: String, planId: String, uuid: String, axisBody: AxisBody) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)/axis/\(uuid)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(axisBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // POST /api/v1/inspections/{id}/plans/{planId}/texts
    func addText(token: String, id: String, planId: String, textBody: TextBody) async throws -> (UuidResponse, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/plans/\(planId)/texts")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(textBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(UuidResponse.self, from: data)
        return (decoded, httpResponse)
    }
    
//    // Получение списка проектов с сервера
//    func getProjects(token: String, pageNum: Int, pageSize: Int) async throws -> (GetProjectsResponse, HTTPURLResponse) {
//        let url = baseURL.appendingPathComponent("/api/v1/inspections")
//        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
//        components.queryItems = [
//            URLQueryItem(name: "pageNum", value: "\(pageNum)"),
//            URLQueryItem(name: "pageSize", value: "\(pageSize)")
//        ]
//        guard let finalURL = components.url else {
//            throw URLError(.badURL)
//        }
//        var request = URLRequest(url: finalURL)
//        request.httpMethod = "GET"
//        request.setValue(token, forHTTPHeaderField: "Cookie")
//        let (data, response) = try await session.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw URLError(.badServerResponse)
//        }
//        let decoded = try JSONDecoder().decode(GetProjectsResponse.self, from: data)
//        return (decoded, httpResponse)
//    }
    
//    func getProjects(token: String, pageNum: Int, pageSize: Int) async throws -> (GetProjectsResponse, HTTPURLResponse)
//    {
//        let url = baseURL.appendingPathComponent("/api/v1/inspections")
//        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
//        components.queryItems = [
//            URLQueryItem(name: "pageNum", value: "(pageNum)"),
//            URLQueryItem(name: "pageSize", value: "(pageSize)")
//        ]
//        guard let finalURL = components.url else {
//            throw URLError(.badURL)
//        }
//        var request = URLRequest(url: finalURL)
//        request.httpMethod = "GET"
//        request.setValue(token, forHTTPHeaderField: "Cookie")
//        let (data, response) = try await session.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw URLError(.badServerResponse)
//        }
//        print("DEBUG [getProjects] Получены данные: (String(data: data, encoding: .utf8)")
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        let decoded = try decoder.decode(GetProjectsResponse.self, from: data)
//        return (decoded, httpResponse)
//    }
    
    func getProjects(token: String, pageNum: Int, pageSize: Int) async throws -> (GetProjectsResponse, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "pageNum", value: "\(pageNum)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("DEBUG [getProjects] Получены данные: \(String(data: data, encoding: .utf8) ?? "Пустой ответ")")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(GetProjectsResponse.self, from: data)
        return (decoded, httpResponse)
    }


    // Получение фото проекта с сервера
//    func getProjectPhoto(token: String, id: String) async throws -> (Data, HTTPURLResponse) {
    func getProjectPhoto(token: String, id: Int) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/main-photo")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }

    // Получение аудио проекта с сервера
//    func getAudioProject(token: String, id: String) async throws -> (Data, HTTPURLResponse) {
    func getAudioProject(token: String, id: Int) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)/audio")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // Новый метод refresh – соответствует эндпоинту @GET("/api/v1/auth/refresh")
    func refresh(token: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // Проверяет подтверждение email через эндпоинт
    //GET /api/v1/account
    func checkEmailConfirmation(token: String) async throws -> (Verified, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/account")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let verified = try JSONDecoder().decode(Verified.self, from: data)
        return (verified, httpResponse)
    }
}
