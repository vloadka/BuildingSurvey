//
//  AudioNotesView.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 28.03.2025.
//

import SwiftUI

struct AudioNotesView: View {
    @StateObject private var viewModel: AudioNotesViewModel

    init(project: Project, repository: GeneralRepository) {
        _viewModel = StateObject(wrappedValue: AudioNotesViewModel(repository: repository, project: project))
    }
    
    var body: some View {
        VStack {
            if viewModel.audioNotes.isEmpty {
                Text("Нет аудиозаметок")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.audioNotes, id: \.self) { note in
                        HStack {
                            // Выводим время записи (можно настроить формат по необходимости)
                            Text(note.timestamp, style: .time)
                            Spacer()
                            Button(action: {
                                viewModel.deleteAudio(note: note)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAudioNotes()
        }
    }
}

