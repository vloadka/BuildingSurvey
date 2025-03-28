//
//  AudioNoteRow.swift
//  BuildingSurvey
//
//  Created by Влада Лодочникова on 28.03.2025.
//

import SwiftUI
import AVFoundation

struct AudioNoteRow: View, Hashable {
    let note: AudioNote
    let onDelete: () -> Void

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false

    var body: some View {
        HStack {
            Text(note.timestamp, style: .time)
            Spacer()
            // Кнопка воспроизведения / остановки
            Button(action: {
                if isPlaying {
                    audioPlayer?.stop()
                    isPlaying = false
                } else {
                    do {
                        audioPlayer = try AVAudioPlayer(data: note.audioData)
                        audioPlayer?.delegate = AudioPlayerDelegateWrapper {
                            isPlaying = false
                        }
                        audioPlayer?.play()
                        isPlaying = true
                    } catch {
                        print("Ошибка воспроизведения аудио: \(error)")
                    }
                }
            }) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())

            // Кнопка удаления
            Button(action: {
                if isPlaying {
                    audioPlayer?.stop()
                    isPlaying = false
                }
                onDelete()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
    
    static func == (lhs: AudioNoteRow, rhs: AudioNoteRow) -> Bool {
        lhs.note.id == rhs.note.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(note.id)
    }
}

class AudioPlayerDelegateWrapper: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

