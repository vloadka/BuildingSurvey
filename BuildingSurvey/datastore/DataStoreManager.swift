//
//  DataStoreManager.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 12.04.2025.
//

import Foundation

struct UserPreferences: Codable {
    var firstName: String
    var secondName: String
    var patronymic: String
    var email: String
    var phoneNumber: String?
    var password: String
    var avatarPath: String
    var refreshToken: String
    var photoMode: Bool
    var authorized: Bool
    static let empty = UserPreferences(
        firstName: "",
        secondName: "",
        patronymic: "",
        email: "",
        phoneNumber: nil,
        password: "",
        avatarPath: "",
        refreshToken: "",
        photoMode: true,
        authorized: false
    )
}

class DataStoreManager: ObservableObject {
    static let shared = DataStoreManager()
    private let userDefaults = UserDefaults.standard
    private let key = "UserPreferencesKey"
    private let jwtKey = "JwtTokenKey"
    
    // Текущее состояние настроек. Если данных нет – возвращается пустой экземпляр.
    var userPreferences: UserPreferences {
        get {
            if let data = userDefaults.data(forKey: key),
               let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) {
                return prefs
            }
            return UserPreferences.empty
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: key)
            }
        }
    }
    
    // Очищает все данные хранилища.
    func clearDataStore() async {
        var prefs = userPreferences
        prefs.firstName = ""
        prefs.secondName = ""
        prefs.patronymic = ""
        prefs.email = ""
        prefs.phoneNumber = nil
        prefs.password = ""
        prefs.avatarPath = ""
        prefs.refreshToken = ""
        prefs.photoMode = true
        prefs.authorized = false
        userPreferences = prefs
    }
    
    // Очищает путь к аватару.
    func clearUserAvatar() async {
        var prefs = userPreferences
        if !prefs.avatarPath.isEmpty {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: prefs.avatarPath) {
                try? fileManager.removeItem(atPath: prefs.avatarPath)
            }
        }
        prefs.avatarPath = ""
        userPreferences = prefs
    }
    
    // Сохраняет данные пользователя.
    // Учтите, что модель UserData из вашего ApiService содержит только: firstName, lastName, patronymic, email.
    // При сохранении lastName сохраняется как secondName.
    func saveUserData(userData: UserData) async {
        var prefs = userPreferences
        prefs.firstName = userData.firstName
        prefs.secondName = userData.lastName
        prefs.patronymic = userData.patronymic
        prefs.email = userData.email
        userPreferences = prefs
    }
    
    // Сохраняет путь к аватару.
    func saveUserAvatar(path: String) async {
        var prefs = userPreferences
        prefs.avatarPath = path
        userPreferences = prefs
    }
    
    // Сохраняет флаг использования фото-режима.
    func savePhotoMode(photoMode: Bool) async {
        var prefs = userPreferences
        prefs.photoMode = photoMode
        userPreferences = prefs
    }
    
    // Сохраняет пароль.
    func savePassword(password: String) async {
        var prefs = userPreferences
        prefs.password = password
        userPreferences = prefs
    }
    
    // Обновляет статус авторизации.
    func updateAuthorized(authorized: Bool) async {
        var prefs = userPreferences
        prefs.authorized = authorized
        userPreferences = prefs
    }
    
    // Обновляет refresh-токен.
    func updateRefreshToken(refreshToken: String) async {
        var prefs = userPreferences
        prefs.refreshToken = refreshToken
        userPreferences = prefs
        print("DEBUG: Обновлён refreshToken в DataStoreManager: \(refreshToken)")
    }

    func getRefreshToken() async -> String {
        let token = userPreferences.refreshToken
        print("DEBUG: Получен refreshToken из DataStoreManager: \(token)")
        return token
    }
    
    // Метод для обновления jwtToken
    func updateJwtToken(token: String) async {
        userDefaults.set(token, forKey: jwtKey)
        print("DEBUG: Обновлён jwtToken в DataStoreManager: \(token)")
    }
    
    // Метод для получения jwtToken
    func getJwtToken() async -> String {
        let token = userDefaults.string(forKey: jwtKey) ?? ""
        print("DEBUG: Получен jwtToken из DataStoreManager: \(token)")
        return token
    }
}
