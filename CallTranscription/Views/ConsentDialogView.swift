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
            Text(LocalizedStringKey("consentDialog.title"))
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityIdentifier("consentDialogTitle")
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(LocalizedStringKey("consentDialog.title.accessibility.label"))

            // Body text explaining legal obligations
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("consentDialog.intro"))
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint(NSLocalizedString("consentDialog.bullet1", comment: "First bullet point"))
                    bulletPoint(NSLocalizedString("consentDialog.bullet2", comment: "Second bullet point"))
                    bulletPoint(NSLocalizedString("consentDialog.bullet3", comment: "Third bullet point"))
                    bulletPoint(NSLocalizedString("consentDialog.bullet4", comment: "Fourth bullet point"))
                }
                .accessibilityElement(children: .combine)

                Text(LocalizedStringKey("consentDialog.responsibility"))
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding(.top, 8)

                Text(LocalizedStringKey("consentDialog.warning"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .accessibilityIdentifier("consentDialogBody")
            .accessibilityLabel(LocalizedStringKey("consentDialog.body.accessibility.label"))

            Divider()

            // Checkbox for "Do not remind me again"
            Toggle(isOn: $doNotRemindAgain) {
                Text(LocalizedStringKey("consentDialog.checkbox.label"))
                    .font(.body)
            }
            .toggleStyle(.checkbox)
            .accessibilityIdentifier("doNotRemindCheckbox")
            .accessibilityLabel(LocalizedStringKey("consentDialog.checkbox.accessibility.label"))
            .accessibilityHint(LocalizedStringKey("consentDialog.checkbox.accessibility.hint"))

            // Buttons
            HStack {
                Spacer()

                Button(LocalizedStringKey("consentDialog.button.quit")) {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("quitButton")
                .accessibilityLabel(LocalizedStringKey("consentDialog.quit.accessibility.label"))
                .accessibilityHint(LocalizedStringKey("consentDialog.quit.accessibility.hint"))

                Button(LocalizedStringKey("consentDialog.button.understand")) {
                    appState.dismissConsentDialog(rememberChoice: doNotRemindAgain)
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("iUnderstandButton")
                .accessibilityLabel(LocalizedStringKey("consentDialog.understand.accessibility.label"))
                .accessibilityHint(LocalizedStringKey("consentDialog.understand.accessibility.hint"))
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
