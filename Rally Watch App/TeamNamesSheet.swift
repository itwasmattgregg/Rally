import SwiftUI

struct TeamNamesSheet: View {
    @Environment(ScoreBoard.self) private var board
    @Environment(\.dismiss) private var dismiss

    @State private var homeDraft = ""
    @State private var awayDraft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Teams") {
                    TextField("Home", text: $homeDraft)
                    TextField("Away", text: $awayDraft)
                }
            }
            .navigationTitle("Names")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        board.homeName = capped(homeDraft, fallback: "HOME")
                        board.awayName = capped(awayDraft, fallback: "AWAY")
                        dismiss()
                    }
                }
            }
            .onAppear {
                homeDraft = board.homeName
                awayDraft = board.awayName
            }
        }
    }

    private func capped(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return fallback }
        return String(trimmed.prefix(8))
    }
}
