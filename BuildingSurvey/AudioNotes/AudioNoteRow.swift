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
    @State private var showDeleteAlert: Bool = false
    @State private var audioDelegate: AudioPlayerDelegateWrapper?  // сохраняем делегата

    // Форматтер для времени:
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }

    var body: some View {
        HStack {
            Text("\(timeFormatter.string(from: note.timestamp)) - \(note.drawingName)")
            Spacer()
            // Кнопка воспроизведения/остановки
            Button(action: {
                if isPlaying {
                    audioPlayer?.stop()
                    isPlaying = false
                } else {
                    do {
                        audioPlayer = try AVAudioPlayer(data: note.audioData)
                        // Создаём и сохраняем делегата, чтобы он не деаллоцировался
                        let delegate = AudioPlayerDelegateWrapper {
                            self.isPlaying = false
                        }
                        self.audioDelegate = delegate
                        audioPlayer?.delegate = delegate
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

            // Кнопка удаления с уведомлением
            Button(action: {
                if isPlaying {
                    audioPlayer?.stop()
                    isPlaying = false
                }
                showDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PlainButtonStyle())
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Удалить аудиозаметку?"),
                    message: Text("Вы точно хотите удалить аудиозаметку? Это действие невозможно отменить."),
                    primaryButton: .destructive(Text("Удалить")) {
                        onDelete()
                    },
                    secondaryButton: .cancel()
                )
            }
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
        DispatchQueue.main.async {
            self.onFinish()
        }
    }
}
