import SwiftUI

/// Selectable number color themes shared by phone/iPad companion and Watch.
/// Mint/Ember matches the product look; others stay high-contrast on charcoal.
enum ScoreNumberTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case mintEmber
    case iceFlame
    case chalk
    case courtGold
    case aquaCoral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mintEmber: "Mint / Ember"
        case .iceFlame: "Ice / Flame"
        case .chalk: "Chalk"
        case .courtGold: "Court Gold"
        case .aquaCoral: "Aqua / Coral"
        }
    }

    var home: Color {
        switch self {
        case .mintEmber: ScoreTheme.home
        case .iceFlame: Color(red: 0.55, green: 0.82, blue: 1.00)
        case .chalk: Color(red: 0.96, green: 0.96, blue: 0.94)
        case .courtGold: Color(red: 0.98, green: 0.82, blue: 0.28)
        case .aquaCoral: Color(red: 0.20, green: 0.88, blue: 0.85)
        }
    }

    var away: Color {
        switch self {
        case .mintEmber: ScoreTheme.away
        case .iceFlame: Color(red: 1.00, green: 0.42, blue: 0.32)
        case .chalk: Color(red: 0.78, green: 0.78, blue: 0.80)
        case .courtGold: Color(red: 0.95, green: 0.45, blue: 0.20)
        case .aquaCoral: Color(red: 1.00, green: 0.48, blue: 0.42)
        }
    }

    /// Soft field wash for Watch OLED; phone scoreboards omit glow for readability.
    var homeGlow: Color {
        switch self {
        case .mintEmber: ScoreTheme.homeGlow
        default: home.opacity(0.45)
        }
    }

    var awayGlow: Color {
        switch self {
        case .mintEmber: ScoreTheme.awayGlow
        default: away.opacity(0.45)
        }
    }
}

/// Selectable numeral fonts for big scores (phone/iPad + Watch).
enum ScoreNumberFont: String, CaseIterable, Identifiable, Codable, Sendable {
    case rounded
    case standard
    case serif
    case mono
    /// Drawn seven-segment digits (digital clock / scoreboard).
    case segmented

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rounded: "Rounded"
        case .standard: "Standard"
        case .serif: "Serif"
        case .mono: "Mono"
        case .segmented: "Segmented"
        }
    }

    /// True when scores should use drawn seven-segment digits instead of a system font.
    var usesSegmentedDigits: Bool { self == .segmented }

    /// Aspect width÷height per digit — used to size scores without clipping.
    var digitAspect: CGFloat {
        usesSegmentedDigits ? 0.58 : 0.74
    }

    /// System font design for non-segmented styles; segmented falls back to mono in text previews.
    var design: Font.Design {
        switch self {
        case .rounded: .rounded
        case .standard: .default
        case .serif: .serif
        case .mono, .segmented: .monospaced
        }
    }
}

/// Codable snapshot for one-way Watch → phone display prefs (never echoed back).
struct ScoreDisplayPrefsSnapshot: Codable, Sendable, Equatable {
    var numberTheme: ScoreNumberTheme
    var numberFont: ScoreNumberFont

    static let `default` = ScoreDisplayPrefsSnapshot(
        numberTheme: .mintEmber,
        numberFont: .rounded
    )
}
