//
//  AudioNotesViewModel.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 28.03.2025.
//

import SwiftUI
import Combine

struct AudioNote: Identifiable, Hashable {
    let id: UUID
    let audioData: Data
    let timestamp: Date
}

class AudioNotesViewModel: ObservableObject {
    @Published var audioNotes: [AudioNote] = []
    let repository: GeneralRepository
    private var project: Project

    init(repository: GeneralRepository, project: Project) {
        self.repository = repository
        self.project = project
        loadAudioNotes()
    }
    
    func loadAudioNotes() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = self.repository.loadAudio(for: self.project)
            DispatchQueue.main.async {
                self.audioNotes = loaded
            }
        }
    }

    
    func deleteAudio(note: AudioNote) {
        repository.deleteAudio(withId: note.id)
        loadAudioNotes()
    }
}

