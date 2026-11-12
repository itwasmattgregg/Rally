import SwiftUI

/// Watch settings: crown scoring toggle + shared scoreboard theme/font.
struct WatchOptionsView: View {
    @Environment(WatchDisplayPreferences.self) private var prefs
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: Binding(
                        get: { prefs.crownAdjustsScore },
                        set: { prefs.crownAdjustsScore = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Crown adjusts score")
                            Text("Off avoids accidental bumps")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(ScoreTheme.inkMuted)
                        }
                    }
                    .tint(ScoreTheme.home)
                }

                Section("Number theme") {
                    ForEach(ScoreNumberTheme.allCases) { option in
                        Button {
                            prefs.numberTheme = option
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(option.home)
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(option.away)
                                    .frame(width: 10, height: 10)
                                Text(option.title)
                                    .foregroundStyle(ScoreTheme.ink)
                                Spacer(minLength: 0)
                                if prefs.numberTheme == option {
                                    Image(systemName: "checkmark")
                                        .font(.system(.caption2, design: .rounded).weight(.bold))
                                        .foregroundStyle(ScoreTheme.home)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Number font") {
                    ForEach(ScoreNumberFont.allCases) { option in
                        Button {
                            prefs.numberFont = option
                        } label: {
                            HStack {
                                Text(option.title)
                                    .font(.system(.body, design: option.design).weight(.semibold))
                                    .foregroundStyle(ScoreTheme.ink)
                                Spacer(minLength: 0)
                                if prefs.numberFont == option {
                                    Image(systemName: "checkmark")
                                        .font(.system(.caption2, design: .rounded).weight(.bold))
                                        .foregroundStyle(ScoreTheme.home)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Options")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
