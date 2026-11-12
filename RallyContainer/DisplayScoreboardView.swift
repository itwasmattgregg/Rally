import SwiftUI

/// Display-only two-score board (phone host chrome or iPad fullscreen).
/// Numbers dominate the viewport; size scales aggressively in landscape when chrome is tucked away.
/// No glow/shadow on numerals — high-contrast ink on charcoal for court readability.
struct DisplayScoreboardView: View {
    let state: GameState
    var theme: ScoreNumberTheme = .mintEmber
    var fontStyle: ScoreNumberFont = .rounded
    /// Extra bottom reserve when the session drawer is expanded (points).
    var bottomChromeInset: CGFloat = 0
    var compactLabels = false

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            let labelBand: CGFloat = compactLabels || landscape ? 22 : 36
            let usableHeight = max(geo.size.height - bottomChromeInset - labelBand - 8, 48)
            let halfWidth = max(geo.size.width * 0.5 - 12, 40)
            let maxDigits = max(digitCount(state.sideA.score), digitCount(state.sideB.score), 1)
            // Fill height in landscape; still clamp to half-width so long scores don't collide.
            let heightFactor: CGFloat = landscape ? 0.96 : 0.78
            let byHeight = usableHeight * heightFactor
            let byWidth = halfWidth / (CGFloat(maxDigits) * fontStyle.digitAspect)
            let scoreSize = min(byHeight, byWidth)

            ZStack {
                fieldBackground

                HStack(spacing: 0) {
                    sideColumn(
                        label: state.sideA.label,
                        score: state.sideA.score,
                        accent: theme.home,
                        scoreSize: scoreSize,
                        landscape: landscape
                    )
                    Rectangle()
                        .fill(ScoreTheme.hairline)
                        .frame(width: 1)
                        .padding(.vertical, landscape ? 12 : 28)
                        .padding(.bottom, bottomChromeInset * 0.15)
                    sideColumn(
                        label: state.sideB.label,
                        score: state.sideB.score,
                        accent: theme.away,
                        scoreSize: scoreSize,
                        landscape: landscape
                    )
                }
                .padding(.bottom, bottomChromeInset)
            }
        }
    }

    private func digitCount(_ score: Int) -> Int {
        String(max(score, 0)).count
    }

    private func sideColumn(
        label: String,
        score: Int,
        accent: Color,
        scoreSize: CGFloat,
        landscape: Bool
    ) -> some View {
        VStack(spacing: landscape || compactLabels ? 4 : 12) {
            Text(label.uppercased())
                .font(.system(landscape || compactLabels ? .caption2 : .title3, design: .rounded).weight(.bold))
                .tracking(landscape ? 1.5 : 2)
                .foregroundStyle(ScoreTheme.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            ScoreHeroText(value: score, size: scoreSize, style: fontStyle, color: accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 4)
    }

    private var fieldBackground: some View {
        LinearGradient(
            colors: [ScoreTheme.fieldTop, ScoreTheme.fieldBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
