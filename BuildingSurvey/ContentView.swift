//
//  ContentView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 18.09.2024.
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}


import SwiftUI

struct ContentView: View {
    var repository: ProjectRepository
    
    var body: some View {
        NavigationView {
            LoginView(repository: repository)
                .navigationBarHidden(true)
        }
    }
}
