import SwiftUI

struct ScoreboardView: View {
    @Environment(ScoreBoard.self) private var board
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    @State private var confirmReset = false
    @State private var showNames = false
    @State private var activeSide: Side = .home
    @State private var crownValue = 0.0
    @State private var lastCrownTick = 0.0

    private enum Side {
        case home, away
    }

    var body: some View {
        ZStack {
            fieldBackground

            VStack(spacing: 0) {
                resetBar

                HStack(spacing: 0) {
                    TeamColumn(
                        name: board.homeName,
                        score: board.homeScore,
                        accent: ScoreTheme.home,
                        glow: ScoreTheme.homeGlow,
                        reduced: isLuminanceReduced,
                        highlighted: activeSide == .home && !isLuminanceReduced,
                        onUp: {
                            activeSide = .home
                            board.bumpHome()
                        },
                        onDown: {
                            activeSide = .home
                            board.dropHome()
                        }
                    )

                    centerDivider

                    TeamColumn(
                        name: board.awayName,
                        score: board.awayScore,
                        accent: ScoreTheme.away,
                        glow: ScoreTheme.awayGlow,
                        reduced: isLuminanceReduced,
                        highlighted: activeSide == .away && !isLuminanceReduced,
                        onUp: {
                            activeSide = .away
                            board.bumpAway()
                        },
                        onDown: {
                            activeSide = .away
                            board.dropAway()
                        }
                    )
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .focusable(true)
        .digitalCrownRotation(
            Binding(
                get: { crownValue },
                set: { newValue in
                    let delta = newValue - lastCrownTick
                    if delta >= 1 {
                        bumpActive()
                        lastCrownTick = newValue
                    } else if delta <= -1 {
                        dropActive()
                        lastCrownTick = newValue
                    }
                    crownValue = newValue
                }
            ),
            from: -1000,
            through: 1000,
            by: 1,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .confirmationDialog("Reset both scores?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                withAnimation(.easeOut(duration: 0.2)) {
                    board.reset()
                }
                WatchHaptics.reset()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func bumpActive() {
        switch activeSide {
        case .home: board.bumpHome()
        case .away: board.bumpAway()
        }
        WatchHaptics.scoreUp()
    }

    private func dropActive() {
        switch activeSide {
        case .home: board.dropHome()
        case .away: board.dropAway()
        }
        WatchHaptics.scoreDown()
    }

    private var resetBar: some View {
        ZStack {
            Button {
                confirmReset = true
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(isLuminanceReduced ? ScoreTheme.inkMuted : ScoreTheme.ink.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ScoreTheme.resetFill)
                            .overlay(Capsule().strokeBorder(ScoreTheme.hairline, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset scores")

            HStack {
                Button {
                    showNames = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isLuminanceReduced ? ScoreTheme.inkMuted : ScoreTheme.ink.opacity(0.7))
                        .frame(width: 26, height: 22)
                        .background(
                            Capsule()
                                .fill(ScoreTheme.resetFill)
                                .overlay(Capsule().strokeBorder(ScoreTheme.hairline, lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit team names")
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
        .padding(.bottom, 4)
        .sheet(isPresented: $showNames) {
            TeamNamesSheet()
                .environment(board)
        }
    }

    private var centerDivider: some View {
        Rectangle()
            .fill(ScoreTheme.hairline)
            .frame(width: 1)
            .padding(.vertical, 10)
            .opacity(isLuminanceReduced ? 0.4 : 1)
    }

    private var fieldBackground: some View {
        ZStack {
            LinearGradient(
                colors: [ScoreTheme.fieldTop, ScoreTheme.fieldBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            if !isLuminanceReduced {
                HStack(spacing: 0) {
                    RadialGradient(
                        colors: [ScoreTheme.homeGlow, .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 70
                    )
                    RadialGradient(
                        colors: [ScoreTheme.awayGlow, .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 70
                    )
                }
                .blur(radius: 8)
                .opacity(0.85)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ScoreboardView()
        .environment(ScoreBoard())
}
