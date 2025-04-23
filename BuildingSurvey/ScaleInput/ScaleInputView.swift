//
//  ScaleInputView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 17.04.2025.
//

import SwiftUI

struct ScaleInputView: View {
  @Binding var isPresented: Bool
  @Binding var text: String
  let onSave: (String) -> Void

  var body: some View {
    ZStack {
      //Color.white.opacity(0.8).edgesIgnoringSafeArea(.all)
      VStack(spacing: 16) {
        Text("Масштаб чертежа")
          .font(.title2).foregroundColor(.white)
        Text("Введите масштаб чертежа в формате X:Y (например, 1:100)")
          .font(.subheadline).foregroundColor(.white)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        TextField("Масштаб", text: $text)
          .keyboardType(.numbersAndPunctuation)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        HStack {
          Button("Отмена") {
            isPresented = false
          }
          .foregroundColor(.white)
          Spacer()
          Button("Сохранить") {
            onSave(text)
          }
          .foregroundColor(.white)
        }
        .padding(.horizontal, 40)
      }
      .padding()
      .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
    }
  }
}
