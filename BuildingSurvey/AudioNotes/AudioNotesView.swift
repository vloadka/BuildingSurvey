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
                    ForEach(viewModel.audioNotes, id: \.id) { note in
                        AudioNoteRow(note: note, onDelete: {
                            viewModel.deleteAudio(note: note)
                        })
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAudioNotes()
        }
    }
}

struct AudioNotesView_Previews: PreviewProvider {
    static var previews: some View {
        // Здесь можно передать тестовый проект и репозиторий
        AudioNotesView(project: Project(id: UUID(), name: "Test Project", coverImageData: nil), repository: GeneralRepository())
    }
}

