//
//  ProfileViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 21.03.2025.
//

import SwiftUI

class ProfileViewModel: ObservableObject {
    // Свойства для фото
    @Published var selectedImage: UIImage? = nil
    @Published var showPhotoPicker: Bool = false

    // Свойства для полей пароля
    @Published var oldPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""

    // Состояние алерта
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    // Флаги для переключения видимости паролей
    @Published var showOldPassword: Bool = false
    @Published var showNewPassword: Bool = false
    @Published var showConfirmPassword: Bool = false

    /// Метод для сохранения изменений.
    /// Если хотя бы одно поле пароля заполнено, выполняется валидация.
    /// Возвращает true, если все проверки пройдены.
    func saveChanges() -> Bool {
        let isPasswordChangeAttempt = !oldPassword.isEmpty || !newPassword.isEmpty || !confirmNewPassword.isEmpty

        if isPasswordChangeAttempt {
            guard !oldPassword.isEmpty else {
                showError("Введите старый пароль")
                return false
            }
            guard newPassword.count >= 5 else {
                showError("Новый пароль должен содержать не менее 5 символов")
                return false
            }
            guard newPassword == confirmNewPassword else {
                showError("Новый пароль и подтверждение не совпадают")
                return false
            }
            // Здесь можно добавить вызов метода для обновления пароля через backend или репозиторий.
        }
        // Сохранение фото можно реализовать здесь при необходимости.
        return true
    }

    /// Устанавливает сообщение об ошибке и показывает алерт.
    func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
