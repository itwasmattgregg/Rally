import SwiftUI

struct MatchSessionView: View {
    @Environment(ScoreBoard.self) private var board
    @Environment(MatchSession.self) private var match

    @State private var confirmEnd = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ScoreTheme.fieldTop, ScoreTheme.fieldBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("VOLLEYBALL")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(ScoreTheme.inkMuted)
                    .tracking(1.2)

                if match.isRunning {
                    Text(MatchSession.clockString(match.elapsed))
                        .font(.scoreHero(size: 34))
                        .foregroundStyle(ScoreTheme.ink)
                        .contentTransition(.numericText())

                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(ScoreTheme.away)
                        Text(heartText)
                            .foregroundStyle(ScoreTheme.ink)
                    }
                    .font(.system(.caption, design: .rounded).weight(.semibold))

                    Text(board.summaryLine)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(ScoreTheme.inkMuted)
                } else {
                    Text("Swipe back to keep score. The match keeps recording.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ScoreTheme.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Spacer(minLength: 0)

                if match.isAvailable {
                    Button(action: primaryAction) {
                        Text(buttonTitle)
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(match.isRunning ? ScoreTheme.away : ScoreTheme.home)
                    .disabled(match.isStarting || match.isEnding)
                } else {
                    Text("Health data isn’t available on this watch.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ScoreTheme.inkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .confirmationDialog("End the volleyball workout?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) {
                match.endMatch(
                    homeScore: board.homeScore,
                    awayScore: board.awayScore,
                    homeName: board.homeName,
                    awayName: board.awayName
                )
                WatchHaptics.matchStop()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The score stays on the board. The match is saved to Health.")
        }
        .alert("Workout", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(match.errorMessage ?? "")
        }
    }

    private var buttonTitle: String {
        if match.isStarting { return "Starting" }
        if match.isEnding { return "Saving" }
        return match.isRunning ? "End" : "Start"
    }

    private var heartText: String {
        guard let heartRate = match.heartRate else { return "—" }
        return "\(Int(heartRate.rounded()))"
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { match.errorMessage != nil },
            set: { if !$0 { match.errorMessage = nil } }
        )
    }

    private func primaryAction() {
        if match.isRunning {
            confirmEnd = true
        } else {
            WatchHaptics.matchStart()
            Task { await match.startVolleyball() }
        }
    }
}

#Preview {
    MatchSessionView()
        .environment(ScoreBoard())
        .environment(MatchSession())
}
