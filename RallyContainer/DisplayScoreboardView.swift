import SwiftUI

/// Display-only two-score board (phone host chrome or iPad fullscreen).
struct DisplayScoreboardView: View {
    let state: GameState
    var compactChrome = false

    var body: some View {
        GeometryReader { geo in
            let scoreSize = min(geo.size.width * 0.28, geo.size.height * 0.42)
            ZStack {
                fieldBackground

                HStack(spacing: 0) {
                    sideColumn(
                        label: state.sideA.label,
                        score: state.sideA.score,
                        accent: ScoreTheme.home,
                        glow: ScoreTheme.homeGlow,
                        scoreSize: scoreSize
                    )
                    Rectangle()
                        .fill(ScoreTheme.hairline)
                        .frame(width: 1)
                        .padding(.vertical, compactChrome ? 24 : 48)
                    sideColumn(
                        label: state.sideB.label,
                        score: state.sideB.score,
                        accent: ScoreTheme.away,
                        glow: ScoreTheme.awayGlow,
                        scoreSize: scoreSize
                    )
                }
            }
        }
    }

    private func sideColumn(
        label: String,
        score: Int,
        accent: Color,
        glow: Color,
        scoreSize: CGFloat
    ) -> some View {
        VStack(spacing: compactChrome ? 8 : 16) {
            Text(label.uppercased())
                .font(.system(compactChrome ? .caption : .title3, design: .rounded).weight(.bold))
                .tracking(2)
                .foregroundStyle(ScoreTheme.inkMuted)
            Text("\(score)")
                .font(.scoreHero(size: scoreSize))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
                .shadow(color: glow, radius: 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fieldBackground: some View {
        ZStack {
            LinearGradient(
                colors: [ScoreTheme.fieldTop, ScoreTheme.fieldBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            HStack(spacing: 0) {
                RadialGradient(
                    colors: [ScoreTheme.homeGlow, .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 220
                )
                RadialGradient(
                    colors: [ScoreTheme.awayGlow, .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 220
                )
            }
            .blur(radius: 12)
            .opacity(0.9)
        }
        .ignoresSafeArea()
    }
}
