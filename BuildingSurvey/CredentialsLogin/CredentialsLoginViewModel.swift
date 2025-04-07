//
//  CredentialsLoginViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 21.03.2025.
//

import SwiftUI

class CredentialsLoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var accessCode: String = ""
    
    @Published var showPassword: Bool = false
    @Published var showAccessCode: Bool = false
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    @Published var navigateToProjectList: Bool = false
    
    var repository: GeneralRepository
    var sendRepository: SendRepository
    
    init(repository: GeneralRepository, sendRepository: SendRepository) {
        self.repository = repository
        self.sendRepository = sendRepository
    }
    
    func loginAction() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        // Проверка корректности email через регулярное выражение
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: trimmedEmail) {
            showError("Введите корректный адрес электронной почты")
            return
        }
        
        // Проверка пароля: минимум 5 символов
        if password.count < 5 {
            showError("Пароль должен содержать не менее 5 символов")
            return
        }
        
        // Проверка кода доступа (secretToken): ровно 6 символа
        if accessCode.count != 6 {
            showError("Код доступа должен содержать ровно 6 символа")
            return
        }
        
        // Формируем запрос на вход с использованием email, password и secretToken
        Task {
            let result = await sendRepository.login(user: UserForSignIn(email: trimmedEmail, password: password, secretToken: accessCode))
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.navigateToProjectList = true
                case .inputDataError:
                    self.showError("Неверный email, пароль или код доступа")
                default:
                    self.showError("Ошибка соединения с сервером")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showAlert = false
        }
    }
}
