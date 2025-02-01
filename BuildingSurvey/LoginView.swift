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
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Text("Checkpoint-K")
                .font(.largeTitle)
                .padding()
            Text("Работа на объекте")
                .font(.subheadline)
                .padding(.bottom, 50)
            NavigationLink(destination: ProjectListView(viewModel: ProjectListViewModel(repository: repository))) {
                Text("Войти")
                    .font(.headline)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
        }
    }
}
