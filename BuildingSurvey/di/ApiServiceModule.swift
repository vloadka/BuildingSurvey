//
//  ApiServiceModule.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 06.04.2025.
//

import Foundation

// Константы таймаутов (в секундах)
private let callTimeout: TimeInterval = 60
private let resourceTimeout: TimeInterval = 60

/// ApiServiceModule реализует выполнение HTTP-запросов с базовой настройкой,
/// логированием и механизмом повторной попытки при неудачных запросах.
class ApiServiceModule {
    static let shared = ApiServiceModule()
    
    private let baseURL = URL(string: "http://192.168.1.73:8080")!
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = callTimeout
        configuration.timeoutIntervalForResource = resourceTimeout
        
        // Добавляем заголовок User-Agent
        configuration.httpAdditionalHeaders = ["User-Agent": "KsupointApp/1.0"]
        
        // Дополнительно можно настроить протокол для логирования запросов через URLProtocol,
        // если потребуется более детальное перехватывание.
        
        self.session = URLSession(configuration: configuration)
    }
    
    /// Универсальный метод для выполнения HTTP-запросов.
    /// - Parameters:
    ///   - endpoint: путь к эндпоинту (например, "api/v1/users")
    ///   - method: HTTP метод (GET, POST, PUT, DELETE и т.д.)
    ///   - parameters: словарь параметров для запроса (для POST/PUT)
    ///   - retries: количество повторных попыток в случае ошибки
    ///   - completion: замыкание с результатом декодирования полученных данных в объект типа T
    func request<T: Decodable>(endpoint: String,
                               method: String = "GET",
                               parameters: [String: Any]? = nil,
                               retries: Int = 1,
                               completion: @escaping (Result<T, Error>) -> Void) {
        
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Если метод не GET и переданы параметры, кодируем их в JSON
        if let parameters = parameters, method != "GET" {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        // Логирование запроса
        print("Отправка запроса: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody {
            print("Параметры: \(String(data: body, encoding: .utf8) ?? "")")
        }
        
        // Функция, реализующая повтор запроса (retry)
        func executeRequest(currentRetry: Int) {
            let task = session.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Получен ответ с кодом: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("Ошибка запроса: \(error.localizedDescription)")
                    if currentRetry > 0 {
                        print("Повтор запроса, оставшихся попыток: \(currentRetry)")
                        executeRequest(currentRetry: currentRetry - 1)
                    } else {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    let noDataError = NSError(domain: "ApiService", code: -1,
                                              userInfo: [NSLocalizedDescriptionKey: "Нет данных в ответе"])
                    completion(.failure(noDataError))
                    return
                }
                
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    print("Ошибка декодирования: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
            task.resume()
        }
        
        executeRequest(currentRetry: retries)
    }
}
