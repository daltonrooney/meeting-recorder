import SwiftUI

/// A modal dialog that informs users about recording consent requirements.
///
/// This dialog appears on first launch to ensure users understand their legal obligation
/// to obtain consent before recording conversations with others. It must be acknowledged
/// before the app can be used.
struct ConsentDialogView: View {
    @EnvironmentObject var appState: AppState
    @State private var doNotRemindAgain = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("Important: Recording Consent Requirements")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityIdentifier("consentDialogTitle")

            // Body text explaining legal obligations
            VStack(alignment: .leading, spacing: 12) {
                Text("Before using this app to record conversations, please understand:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Recording laws vary significantly by jurisdiction")
                    bulletPoint("Some regions require only one party's consent (one-party consent states)")
                    bulletPoint("Other regions require all parties to consent before recording (two-party or all-party consent)")
                    bulletPoint("International laws differ dramatically across countries")
                }

                Text("You are solely responsible for ensuring compliance with all applicable laws in your jurisdiction before recording any conversation.")
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding(.top, 8)

                Text("Failure to obtain proper consent may result in civil or criminal liability.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .accessibilityIdentifier("consentDialogBody")

            Divider()

            // Checkbox for "Do not remind me again"
            Toggle(isOn: $doNotRemindAgain) {
                Text("Do not remind me again")
                    .font(.body)
            }
            .toggleStyle(.checkbox)
            .accessibilityIdentifier("doNotRemindCheckbox")
            .accessibilityLabel("Do not remind me again")

            // Buttons
            HStack {
                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("quitButton")
                .accessibilityLabel("Quit")

                Button("I Understand") {
                    appState.dismissConsentDialog(rememberChoice: doNotRemindAgain)
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("iUnderstandButton")
                .accessibilityLabel("I Understand")
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 550)
        .fixedSize(horizontal: true, vertical: false)
    }

    /// Helper to create a bullet point with text.
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ConsentDialogView()
        .environmentObject(AppState())
}
