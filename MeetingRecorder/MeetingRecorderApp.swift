import SwiftUI

@main
struct MeetingRecorderApp: App {
    var body: some Scene {
        MenuBarExtra {
            Text("MeetingRecorder")
        } label: {
            Image(systemName: "waveform.circle")
        }
    }
}
