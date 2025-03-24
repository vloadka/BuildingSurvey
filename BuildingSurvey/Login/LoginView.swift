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
            NavigationLink(destination: CredentialsLoginView(viewModel: CredentialsLoginViewModel(repository: repository))) {
                Text("Войти")
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
