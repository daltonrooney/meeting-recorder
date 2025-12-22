import SwiftUI

/// A draggable token tag that can be inserted into the filename template
struct TokenTag: View {
    let token: String
    var onTap: (@Sendable (String) -> Void)?

    var body: some View {
        Text(token)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(12)
            .accessibilityIdentifier(accessibilityID)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .onDrag {
                NSItemProvider(object: token as NSString)
            }
            .onTapGesture {
                onTap?(token)
            }
    }

    // MARK: - Accessibility

    private var accessibilityID: String {
        switch token {
        case "{date}":
            return "tokenTagDate"
        case "{time}":
            return "tokenTagTime"
        default:
            return "tokenTag\(token)"
        }
    }

    private var accessibilityLabel: String {
        switch token {
        case "{date}":
            return "Date token"
        case "{time}":
            return "Time token"
        default:
            return "\(token) token"
        }
    }

    private var accessibilityHint: String {
        "Drag to insert \(token) token, or tap to insert at end of template"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        HStack(spacing: 8) {
            TokenTag(token: "{date}")
            TokenTag(token: "{time}")
        }
        .padding()

        Text("Example: meeting_{date}_{time}.txt")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .frame(width: 300)
}
