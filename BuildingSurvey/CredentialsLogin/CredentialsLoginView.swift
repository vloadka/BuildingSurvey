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
            
            // Поле для ввода имени
            VStack(alignment: .leading) {
                Text("Имя")
                TextField("Введите имя", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Поле для ввода пароля с кнопкой показа/скрытия
            VStack(alignment: .leading) {
                Text("Пароль")
                ZStack(alignment: .trailing) {
                    Group {
                        if viewModel.showPassword {
                            TextField("Введите пароль", text: $viewModel.password)
                        } else {
                            SecureField("Введите пароль", text: $viewModel.password)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        viewModel.showPassword.toggle()
                    }) {
                        Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 8)
                }
            }
            
            // Поле для ввода кода доступа с кнопкой показа/скрытия
            VStack(alignment: .leading) {
                Text("Код доступа")
                ZStack(alignment: .trailing) {
                    Group {
                        if viewModel.showAccessCode {
                            TextField("Введите код доступа", text: $viewModel.accessCode)
                        } else {
                            SecureField("Введите код доступа", text: $viewModel.accessCode)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        viewModel.showAccessCode.toggle()
                    }) {
                        Image(systemName: viewModel.showAccessCode ? "eye.slash" : "eye")
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 8)
                }
            }
            
            // Кнопка для входа с черным фоном
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
            
            // Скрытый NavigationLink для перехода на экран ProjectListView
            NavigationLink(
                destination: ProjectListView(viewModel: ProjectListViewModel(repository: viewModel.repository)),
                isActive: $viewModel.navigateToProjectList,
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
        NavigationView {
            CredentialsLoginView(viewModel: CredentialsLoginViewModel(repository: GeneralRepository()))
        }
    }
}


