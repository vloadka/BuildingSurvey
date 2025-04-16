//
//  EmailConfirmationView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 13.04.2025.
//

import SwiftUI

struct EmailConfirmationView: View {
    @StateObject var viewModel: EmailConfirmationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()  // верхний spacer для центрирования
            VStack(spacing: 20) {
                Text("Подтвердите ваш email!")
                    .font(.title)
                
                Text("""
Мы отправили вам письмо с ссылкой для подтверждения. Проверьте вашу почту, включая папку "Спам", а если письмо не пришло - нажмите "Отправить ещё раз".
Если вы подтвердили email - нажмите "Проверить статус".
""")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    viewModel.resendEmail()
                }) {
                    if viewModel.resendButtonDisabled {
                        Text("\(viewModel.resendCountdown)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    } else {
                        Text("Отправить ещё раз")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black) // черный фон кнопки
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.resendButtonDisabled)
                
                Button(action: {
                    viewModel.checkStatus()
                }) {
                    if viewModel.checkButtonDisabled {
                        Text("\(viewModel.checkCountdown)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    } else {
                        Text("Проверить статус")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.checkButtonDisabled)
            }
            .padding()
            Spacer() // нижний spacer для центрирования контента
        }
        .padding()
        .alert(isPresented: $viewModel.showAlert) {
            // Если почта подтверждена, по нажатию на OK происходит dismiss
            if viewModel.emailIsVerified {
                return Alert(
                    title: Text("Информация"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"), action: {
                        dismiss()
                    })
                )
            } else {
                return Alert(
                    title: Text("Информация"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct EmailConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = GeneralRepository()
        let sendRepository = SendRepository(apiService: ApiService.shared,
                                            generalRepository: repository,
                                            customWorkManager: DummyCustomWorkManager())
        let viewModel = EmailConfirmationViewModel(sendRepository: sendRepository, repository: repository)
        NavigationView {
            EmailConfirmationView(viewModel: viewModel)
        }
    }
}
