//
//  CredentialsLoginViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 21.03.2025.
//

import SwiftUI

class CredentialsLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var accessCode: String = ""
    
    @Published var showPassword: Bool = false
    @Published var showAccessCode: Bool = false
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    @Published var navigateToProjectList: Bool = false
    
    var repository: GeneralRepository
    
    init(repository: GeneralRepository) {
        self.repository = repository
    }
    
    // Метод для обработки нажатия кнопки входа
    func loginAction() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        
        // Проверка имени: не пустое и начинается с заглавной буквы
        if trimmedUsername.isEmpty {
            showError("Имя не должно быть пустым")
            return
        }
        if let first = trimmedUsername.first, !first.isUppercase {
            showError("Имя должно начинаться с заглавной буквы")
            return
        }
        
        // Проверка пароля: минимум 5 символов, наличие букв и цифр
        if password.count < 5 {
            showError("Пароль должен содержать не менее 5 символов")
            return
        }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        if !hasLetter || !hasDigit {
            showError("Пароль должен содержать буквы и цифры")
            return
        }
        
        // Проверка кода доступа: ровно 4 символа
        if accessCode.count != 4 {
            showError("Код доступа должен содержать ровно 4 символа")
            return
        }
        
        // Все проверки пройдены – осуществляем переход на экран списка проектов
        navigateToProjectList = true
    }
    
    // Метод для отображения ошибки с автоскрытием через 5 секунд
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showAlert = false
        }
    }
}

