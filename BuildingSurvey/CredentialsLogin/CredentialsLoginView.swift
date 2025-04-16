//
//  CredentialsLoginView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 21.03.2025.
//

import SwiftUI

struct CredentialsLoginView: View {
    @StateObject var viewModel: CredentialsLoginViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Вход в систему")
                .font(.title)
            
            VStack(alignment: .leading) {
                Text("Почта")
                TextField("Введите почту", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Пароль")
                ZStack(alignment: .trailing) {
                    if viewModel.showPassword {
                        TextField("Введите пароль", text: $viewModel.password)
                    } else {
                        SecureField("Введите пароль", text: $viewModel.password)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showPassword.toggle()
                        }) {
                            Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 8)
                    }
                )
            }
            
            VStack(alignment: .leading) {
                Text("Код доступа")
                ZStack(alignment: .trailing) {
                    if viewModel.showAccessCode {
                        TextField("Введите код доступа", text: $viewModel.accessCode)
                    } else {
                        SecureField("Введите код доступа", text: $viewModel.accessCode)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showAccessCode.toggle()
                        }) {
                            Image(systemName: viewModel.showAccessCode ? "eye.slash" : "eye")
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 8)
                    }
                )
            }
            
            Button(action: {
                viewModel.loginAction()
            }) {
                Text("Войти")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            // Навигация в зависимости от результата проверки email.
            NavigationLink(
                destination: ProjectListView(viewModel: ProjectListViewModel(repository: viewModel.repository)),
                isActive: $viewModel.navigateToProjectList,
                label: { EmptyView() }
            )
            
            NavigationLink(
                destination: EmailConfirmationView(viewModel: EmailConfirmationViewModel(sendRepository: viewModel.sendRepository, repository: viewModel.repository)),
                isActive: $viewModel.navigateToEmailConfirmation,
                label: { EmptyView() }
            )
        }
        .padding()
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Ошибка"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct CredentialsLoginView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = GeneralRepository()
        let sendRepository = SendRepository(apiService: ApiService.shared,
                                            generalRepository: repository,
                                            customWorkManager: DummyCustomWorkManager())
        NavigationView {
            CredentialsLoginView(viewModel: CredentialsLoginViewModel(repository: repository, sendRepository: sendRepository))
        }
    }
}


