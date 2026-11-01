import SwiftUI

/// Selectable number color themes for phone/iPad companion boards.
/// Mint/Ember matches the Watch product look; others stay high-contrast on charcoal.
enum CompanionNumberTheme: String, CaseIterable, Identifiable, Codable {
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

/// Persisted companion display prefs (theme + whether session chrome is open).
@Observable
final class CompanionDisplayPreferences {
    private static let themeKey = "rally.companion.numberTheme"
    private static let chromeKey = "rally.companion.chromeExpanded"

    var numberTheme: CompanionNumberTheme {
        didSet { UserDefaults.standard.set(numberTheme.rawValue, forKey: Self.themeKey) }
    }

    /// When false, QR/session chrome tucks away so scores dominate.
    var chromeExpanded: Bool {
        didSet { UserDefaults.standard.set(chromeExpanded, forKey: Self.chromeKey) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.themeKey),
           let saved = CompanionNumberTheme(rawValue: raw) {
            numberTheme = saved
        } else {
            numberTheme = .mintEmber
        }
        if UserDefaults.standard.object(forKey: Self.chromeKey) != nil {
            chromeExpanded = UserDefaults.standard.bool(forKey: Self.chromeKey)
        } else {
            // First launch: show chrome so host can share the code, then user can tuck it away.
            chromeExpanded = true
        }
    }
}
