//
//  LoginView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 30.09.2024.
//

import SwiftUI

struct LoginView: View {
    var repository: GeneralRepository
    
    var body: some View {
        // Создаем sendRepository для передачи в RegistrationViewModel
        let sendRepository = SendRepository(apiService: ApiService.shared,
                                            generalRepository: repository,
                                            dataStoreManager: DummyDataStoreManager(),
                                            customWorkManager: DummyCustomWorkManager())
        
        VStack {
            Spacer()
            Image("Subtract")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Text("Ksupoint")
                .font(.largeTitle)
                .padding()
            Text("Работа на объекте")
                .font(.subheadline)
                .padding(.bottom, 50)
            NavigationLink(destination: CredentialsLoginView(viewModel: CredentialsLoginViewModel(repository: repository, sendRepository: sendRepository))) {
                Text("Войти")
                    .font(.headline)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer().frame(height: 20)
            
            NavigationLink(destination: RegistrationView(viewModel: RegistrationViewModel(repository: repository, sendRepository: sendRepository))) {
                Text("Регистрация")
                    .font(.headline)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
    }
}

