//
//  RegistrationView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 06.04.2025.
//

import SwiftUI

struct SquareCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(.black)
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RegistrationView: View {
    @StateObject var viewModel: RegistrationViewModel
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Регистрация")
                    .font(.largeTitle)
                    .padding(.top, 20)
                
                // Поле ввода Фамилии
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Фамилия", text: $viewModel.lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if let error = viewModel.lastNameError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Поле ввода Имени
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Имя", text: $viewModel.firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if let error = viewModel.firstNameError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Поле ввода Отчества
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Отчество", text: $viewModel.patronymic)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if let error = viewModel.patronymicError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Поле ввода Электронной почты
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Электронная почта", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                    if let error = viewModel.emailError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Поле ввода Пароля
                VStack(alignment: .leading, spacing: 4) {
                    Text("Пароль")
                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Пароль", text: $viewModel.password)
                            } else {
                                SecureField("Пароль", text: $viewModel.password)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 8)
                    }
                    if let error = viewModel.passwordError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Поле ввода Подтверждения пароля
                VStack(alignment: .leading, spacing: 4) {
                    Text("Подтверждение пароля")
                    ZStack(alignment: .trailing) {
                        Group {
                            if showConfirmPassword {
                                TextField("Подтверждение пароля", text: $viewModel.confirmPassword)
                            } else {
                                SecureField("Подтверждение пароля", text: $viewModel.confirmPassword)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 8)
                    }
                    if let error = viewModel.passwordMatchError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Чекбоксы соглашений с выравниванием влево
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: $viewModel.agreeToDataPolicy) {
                        HStack(spacing: 4) {
                            Text("Согласен с")
                            Button(action: {
                                if let url = Bundle.main.url(forResource: "DataPolicy", withExtension: "pdf") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("политикой обработки персональных данных")
                                    .underline()
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .toggleStyle(SquareCheckboxStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Toggle(isOn: $viewModel.acceptUserAgreement) {
                        HStack(spacing: 4) {
                            Text("Ознакомлен с")
                            Button(action: {
                                if let url = Bundle.main.url(forResource: "UserAgreement", withExtension: "pdf") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("пользовательским соглашением")
                                    .underline()
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .toggleStyle(SquareCheckboxStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let error = viewModel.agreementsError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Кнопка регистрации
                Button(action: {
                    viewModel.registerAction()
                }) {
                    Text("Регистрация")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.vertical, 20)
                
                // Скрытый переход на ProjectListView после успешной регистрации
                NavigationLink(
                    destination: ProjectListView(viewModel: ProjectListViewModel(repository: viewModel.repository)),
                    isActive: $viewModel.navigateToProjectList,
                    label: { EmptyView() }
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = GeneralRepository()
        let sendRepository = SendRepository(apiService: ApiService.shared,
                                            generalRepository: repository,
                                            customWorkManager: DummyCustomWorkManager())
        let viewModel = RegistrationViewModel(repository: repository, sendRepository: sendRepository)
        
        return NavigationView {
            RegistrationView(viewModel: viewModel)
        }
    }
}
