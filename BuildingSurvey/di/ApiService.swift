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

class ApiService {
    static let shared = ApiService()
    let baseURL = URL(string: "http://192.168.0.189:8080")!
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
        
        // Выполнение запроса без тела
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(InspectionIdResponse.self, from: data)
        return (decoded, httpResponse)
    }
    
    // PUT /api/v1/inspections/{id}
    func addNameProject(token: String, id: String, projectInfo: ProjectInfo) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Cookie")
        request.httpBody = try JSONEncoder().encode(projectInfo)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
    
    // Multipart POST /api/v1/inspections/{id}/main-photo
    func addAvatarProject(token: String, id: String, fileData: Data, fileName: String) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/project/addAvatar")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        // Формируем multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Если требуется, передаём идентификатор проекта в теле запроса
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(id)\r\n".data(using: .utf8)!)
        
        // Добавляем файл обложки
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
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
        let mimeType = "image/jpeg"
        
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
        let decoded = try JSONDecoder().decode(IdResponse.self, from: data)
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }

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
    
    // Получение списка проектов с сервера
    func getProjects(token: String, pageNum: Int, pageSize: Int) async throws -> (GetProjectsResponse, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent("/api/v1/inspections")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [ URLQueryItem(name: "pageNum", value: "(pageNum)"),
                                  URLQueryItem(name: "pageSize", value: "(pageSize)") ]
        
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
        let decoded = try JSONDecoder().decode(GetProjectsResponse.self, from: data) 
        return (decoded, httpResponse)
    }

    // Получение фото проекта с сервера
    func getProjectPhoto(token: String, id: String) async throws -> (Data, HTTPURLResponse) {
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
    func getAudioProject(token: String, id: String) async throws -> (Data, HTTPURLResponse) {
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
}
