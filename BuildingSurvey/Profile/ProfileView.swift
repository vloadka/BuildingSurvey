//
//  ProfileView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 21.03.2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Заголовок "Профиль"
                Text("Профиль")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                
                // Раздел загрузки фото
                VStack(spacing: 10) {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    }
                    Button("Загрузить фото") {
                        viewModel.showPhotoPicker = true
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                }
                
                Divider()
                
                // Раздел изменения пароля
                VStack(spacing: 15) {
                    // Старый пароль
                    HStack {
                        if viewModel.showOldPassword {
                            TextField("Старый пароль", text: $viewModel.oldPassword)
                        } else {
                            SecureField("Старый пароль", text: $viewModel.oldPassword)
                        }
                        Button(action: {
                            viewModel.showOldPassword.toggle()
                        }) {
                            Image(systemName: viewModel.showOldPassword ? "eye.slash" : "eye")
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    
                    // Новый пароль
                    HStack {
                        if viewModel.showNewPassword {
                            TextField("Новый пароль", text: $viewModel.newPassword)
                        } else {
                            SecureField("Новый пароль", text: $viewModel.newPassword)
                        }
                        Button(action: {
                            viewModel.showNewPassword.toggle()
                        }) {
                            Image(systemName: viewModel.showNewPassword ? "eye.slash" : "eye")
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    
                    // Подтверждение нового пароля
                    HStack {
                        if viewModel.showConfirmPassword {
                            TextField("Подтвердите новый пароль", text: $viewModel.confirmNewPassword)
                        } else {
                            SecureField("Подтвердите новый пароль", text: $viewModel.confirmNewPassword)
                        }
                        Button(action: {
                            viewModel.showConfirmPassword.toggle()
                        }) {
                            Image(systemName: viewModel.showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    if viewModel.saveChanges() {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Сохранить")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PhotoLoader(selectedImage: $viewModel.selectedImage)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Ошибка"),
                      message: Text(viewModel.alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
