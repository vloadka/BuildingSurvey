//
//  RegistrationViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 06.04.2025.
//

import Foundation

class RegistrationViewModel: ObservableObject {
    @Published var lastName: String = ""
    @Published var firstName: String = ""
    @Published var patronymic: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var agreeToDataPolicy: Bool = false
    @Published var acceptUserAgreement: Bool = false
    
    @Published var navigateToProjectList: Bool = false
    
    // Ошибки валидации
    @Published var lastNameError: String?
    @Published var firstNameError: String?
    @Published var patronymicError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var passwordMatchError: String?
    @Published var agreementsError: String?
    
    var repository: GeneralRepository
    var sendRepository: SendRepository
    
    init(repository: GeneralRepository, sendRepository: SendRepository) {
        self.repository = repository
        self.sendRepository = sendRepository
    }
    
    func validateFields() -> Bool {
        var valid = true
        
        // Сброс ошибок
        lastNameError = nil
        firstNameError = nil
        patronymicError = nil
        emailError = nil
        passwordError = nil
        passwordMatchError = nil
        agreementsError = nil
        
        // Проверка Фамилии
        if lastName.isEmpty || !(lastName.first?.isUppercase ?? false) {
            lastNameError = "Фамилия должна начинаться с заглавной буквы"
            valid = false
        }
        // Проверка Имени
        if firstName.isEmpty || !(firstName.first?.isUppercase ?? false) {
            firstNameError = "Имя должно начинаться с заглавной буквы"
            valid = false
        }
        // Проверка Отчества
        if patronymic.isEmpty || !(patronymic.first?.isUppercase ?? false) {
            patronymicError = "Отчество должно начинаться с заглавной буквы"
            valid = false
        }
        
        // Проверка электронной почты
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            emailError = "Введите корректный адрес электронной почты, например: example@gmail.com"
            valid = false
        }
        
        // Проверка длины пароля
        if password.count < 5 {
            passwordError = "Пароль должен содержать не менее 5 символов"
            valid = false
        }
        
        // Проверка совпадения паролей
        if password != confirmPassword {
            passwordMatchError = "Пароли не совпадают"
            valid = false
        }
        
        // Проверка чекбоксов соглашений
        if !agreeToDataPolicy || !acceptUserAgreement {
            agreementsError = "Необходимо согласиться с политикой обработки персональных данных и пользовательским соглашением"
            valid = false
        }
        
        return valid
    }
    
    func registerAction() {
        if validateFields() {
            let newUser = UserForSignUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                patronymic: patronymic
            )
            
            Task {
                let response = await sendRepository.registerNewUser(user: newUser)
                DispatchQueue.main.async {
                    switch response {
                    case .success:
                        self.navigateToProjectList = true
                    case .emailUnique:
                        self.emailError = "Пользователь с таким email уже существует"
                    default:
                        self.emailError = "Ошибка регистрации. Попробуйте позже."
                    }
                }
            }
        }
    }
}

