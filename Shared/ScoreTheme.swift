import SwiftUI

/// Night-court palette: charcoal field, mint home, ember away.
/// Tuned for OLED watch faces and phone/iPad dark displays — never purple, never cream.
enum ScoreTheme {
    static let fieldTop = Color(red: 0.05, green: 0.07, blue: 0.09)
    static let fieldBottom = Color(red: 0.09, green: 0.11, blue: 0.13)

    static let home = Color(red: 0.22, green: 0.92, blue: 0.72)      // mint
    static let away = Color(red: 1.00, green: 0.55, blue: 0.28)      // ember

    static let homeGlow = Color(red: 0.10, green: 0.45, blue: 0.38).opacity(0.55)
    static let awayGlow = Color(red: 0.55, green: 0.25, blue: 0.12).opacity(0.55)

    static let ink = Color.white.opacity(0.92)
    static let inkMuted = Color.white.opacity(0.45)
    static let hairline = Color.white.opacity(0.12)

    static let resetFill = Color.white.opacity(0.08)
}

extension Font {
    /// Big score numerals for system-font styles. Prefer `ScoreHeroText` so Segmented works.
    static func scoreHero(size: CGFloat, style: ScoreNumberFont = .rounded) -> Font {
        .system(size: size, weight: .heavy, design: style.design)
    }

    static func scoreLabel(_ style: Font.TextStyle = .caption2) -> Font {
        .system(style, design: .rounded).weight(.semibold)
    }
}
