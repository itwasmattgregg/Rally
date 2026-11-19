import SwiftUI

/// Display-only two-score board (phone host chrome or iPad fullscreen).
/// Landscape: each score stays in its half; numeral center sits at 50% height.
/// No glow/shadow on numerals — high-contrast ink on charcoal for court readability.
struct DisplayScoreboardView: View {
    let state: GameState
    var theme: ScoreNumberTheme = .mintEmber
    var fontStyle: ScoreNumberFont = .rounded
    /// Optional bottom reserve (points). Companion Host/Join pass 0 so scores stay full-bleed;
    /// session chrome overlays from the trailing edge instead of eating score height.
    var bottomChromeInset: CGFloat = 0
    var compactLabels = false

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            let fullWidth = geo.size.width
            let fullHeight = geo.size.height
            let dividerWidth: CGFloat = 1
            // Strict halves that still leave room for the center hairline.
            let halfWidth = max((fullWidth - dividerWidth) * 0.5, 1)
            let sideInset: CGFloat = landscape ? 8 : 10
            let maxScoreWidth = max(halfWidth - sideInset * 2, 24)
            let maxDigits = max(digitCount(state.sideA.score), digitCount(state.sideB.score), 1)
            let labelBand: CGFloat = compactLabels || landscape ? 22 : 36
            // Keep vertical room so a tall glyph still clears labels + bottom chrome.
            let usableHeight = max(fullHeight - bottomChromeInset - labelBand - 8, 48)
            let heightFactor: CGFloat = landscape ? 0.92 : 0.78
            let byHeight = usableHeight * heightFactor
            let byWidth = fontStyle.maxDigitHeight(digitCount: maxDigits, maxWidth: maxScoreWidth)
            let scoreSize = min(byHeight, byWidth)

            ZStack {
                fieldBackground

                HStack(spacing: 0) {
                    sideHalf(
                        label: state.sideA.label,
                        score: state.sideA.score,
                        accent: theme.home,
                        scoreSize: scoreSize,
                        halfWidth: halfWidth,
                        maxScoreWidth: maxScoreWidth,
                        landscape: landscape,
                        sideInset: sideInset
                    )
                    Rectangle()
                        .fill(ScoreTheme.hairline)
                        .frame(width: dividerWidth)
                        .padding(.vertical, landscape ? 12 : 28)
                    sideHalf(
                        label: state.sideB.label,
                        score: state.sideB.score,
                        accent: theme.away,
                        scoreSize: scoreSize,
                        halfWidth: halfWidth,
                        maxScoreWidth: maxScoreWidth,
                        landscape: landscape,
                        sideInset: sideInset
                    )
                }
                .frame(
                    width: fullWidth,
                    height: max(fullHeight - bottomChromeInset, 1),
                    alignment: .center
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func digitCount(_ score: Int) -> Int {
        String(max(score, 0)).count
    }

    /// One half of the board. Score glyph is centered at 50% height; label floats above.
    private func sideHalf(
        label: String,
        score: Int,
        accent: Color,
        scoreSize: CGFloat,
        halfWidth: CGFloat,
        maxScoreWidth: CGFloat,
        landscape: Bool,
        sideInset: CGFloat
    ) -> some View {
        ZStack {
            // True vertical center of the half — labels do not shift the numeral.
            ScoreHeroText(value: score, size: scoreSize, style: fontStyle, color: accent)
                .frame(maxWidth: maxScoreWidth, maxHeight: .infinity)
                .frame(width: maxScoreWidth, alignment: .center)

            VStack(spacing: 0) {
                Text(label.uppercased())
                    .font(.system(landscape || compactLabels ? .caption2 : .title3, design: .rounded).weight(.bold))
                    .tracking(landscape ? 1.5 : 2)
                    .foregroundStyle(ScoreTheme.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, landscape || compactLabels ? 6 : 12)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, sideInset)
        }
        .frame(width: halfWidth)
        .frame(maxHeight: .infinity)
        .clipped()
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
