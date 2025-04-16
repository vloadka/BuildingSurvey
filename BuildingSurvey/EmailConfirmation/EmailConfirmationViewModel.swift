//
//  EmailConfirmationViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 13.04.2025.
//

import SwiftUI
import Combine

class EmailConfirmationViewModel: ObservableObject {
    let sendRepository: SendRepository
    let repository: GeneralRepository
    
    // Таймеры и состояния для кнопок
    @Published var resendCountdown: Int = 0
    @Published var checkCountdown: Int = 0
    @Published var resendButtonDisabled: Bool = false
    @Published var checkButtonDisabled: Bool = false
    
    @Published var alertMessage: String? = nil
    @Published var showAlert: Bool = false
    
    // Флаг, который становится true, если почта подтверждена
    @Published var emailIsVerified: Bool = false
    
    private var resendTimer: Timer?
    private var checkTimer: Timer?
    
    init(sendRepository: SendRepository, repository: GeneralRepository) {
        self.sendRepository = sendRepository
        self.repository = repository
    }
    
    /// Действие для кнопки "Отправить ещё раз"
    func resendEmail() {
        alertMessage = "Письмо было отправлено"
        showAlert = true
        
        resendButtonDisabled = true
        resendCountdown = 30
        
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if self.resendCountdown > 0 {
                self.resendCountdown -= 1
            } else {
                self.resendButtonDisabled = false
                timer.invalidate()
            }
        }
        // Если реализовано – можно вызвать метод отправки письма:
        // Task { await sendRepository.resendVerificationEmail() }
    }
    
    /// Действие для кнопки "Проверить статус"
    func checkStatus() {
        checkButtonDisabled = true
        checkCountdown = 10
        
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if self.checkCountdown > 0 {
                self.checkCountdown -= 1
            } else {
                timer.invalidate()
                self.performVerification()
            }
        }
    }
    
    /// Выполняет реальную проверку верификации email.
    /// Этот метод вызывает sendRepository.checkEmailConfirmation(),
    /// который должен вернуть true, если почта подтверждена, и false иначе.
    func performVerification() {
        Task {
            let (response, emailVerified) = await sendRepository.checkEmailConfirmation()
            DispatchQueue.main.async {
                if emailVerified {
                    self.alertMessage = "Почта подтверждена"
                    self.showAlert = true
                    self.emailIsVerified = true
                } else {
                    self.alertMessage = "Email не подтвержден! Попробуйте еще раз"
                    self.showAlert = true
                    self.checkButtonDisabled = false
                }
            }
        }
    }
}
