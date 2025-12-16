import SwiftUI

@main
struct CallTranscriptionApp: App {
    var body: some Scene {
        MenuBarExtra {
            Text("Olive - Call Transcription")
        } label: {
            Image(systemName: "waveform.circle")
        }
    }
}
