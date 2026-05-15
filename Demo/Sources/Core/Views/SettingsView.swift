import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL = ""
    @State private var ownerId   = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                SeerSpinningIcon(size: 28, cornerRadius: 7)
                Text("Settings")
                    .font(.seerSerif(20, weight: .medium))
                    .foregroundStyle(Color.seerInk)
            }
            .padding(.bottom, 28)

            // Server URL
            fieldGroup(
                label: "Server URL",
                hint: "The SeerMini server address.",
                content: {
                    TextField("http://127.0.0.1:8080", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.seerMono(12))
                }
            )

            Spacer().frame(height: 20)

            // Owner ID
            fieldGroup(
                label: "Owner ID",
                hint: "Documents are indexed under this ID. Use the same ID to search them across sessions.",
                content: {
                    TextField("seer-demo", text: $ownerId)
                        .textFieldStyle(.roundedBorder)
                        .font(.seerMono(12))
                }
            )

            Spacer()

            Divider().padding(.bottom, 16)

            // Buttons
            HStack {
                // Server status
                ServerStatusDot(reachable: appState.serverReachable)
                Button("Test Connection") {
                    appState.serverURL = serverURL
                    Task { await appState.checkHealth() }
                }
                .font(.seerSans(12))
                .buttonStyle(.plain)
                .foregroundStyle(Color.seerGold)

                Spacer()

                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Save") {
                    appState.serverURL = serverURL
                    appState.ownerId   = ownerId
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color.seerGold)
            }
        }
        .padding(28)
        .frame(width: 400, height: 300)
        .background(Color.seerBG)
        .onAppear {
            serverURL = appState.serverURL
            ownerId   = appState.ownerId
        }
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(
        label: String,
        hint: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.seerSans(12, weight: .medium))
                .foregroundStyle(Color.seerInk.opacity(0.60))
            content()
            Text(hint)
                .font(.seerSans(11))
                .foregroundStyle(Color.seerInk.opacity(0.30))
        }
    }
}
