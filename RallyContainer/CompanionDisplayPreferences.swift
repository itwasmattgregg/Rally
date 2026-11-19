import SwiftUI

/// Persisted companion display prefs (theme, font, session chrome).
/// Themes/fonts share models with Watch; Watch may push prefs one-way — phone never echoes back.
@Observable
final class CompanionDisplayPreferences {
    private static let themeKey = "rally.companion.numberTheme"
    private static let fontKey = "rally.companion.numberFont"
    private static let chromeKey = "rally.companion.chromeExpanded"

    var numberTheme: ScoreNumberTheme {
        didSet { UserDefaults.standard.set(numberTheme.rawValue, forKey: Self.themeKey) }
    }

    var numberFont: ScoreNumberFont {
        didSet { UserDefaults.standard.set(numberFont.rawValue, forKey: Self.fontKey) }
    }

    /// When false, trailing-edge session chrome is hidden so scores are full-bleed.
    var chromeExpanded: Bool {
        didSet { UserDefaults.standard.set(chromeExpanded, forKey: Self.chromeKey) }
    }

    var snapshot: ScoreDisplayPrefsSnapshot {
        ScoreDisplayPrefsSnapshot(numberTheme: numberTheme, numberFont: numberFont)
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.themeKey),
           let saved = ScoreNumberTheme(rawValue: raw) {
            numberTheme = saved
        } else {
            numberTheme = .mintEmber
        }
        if let raw = UserDefaults.standard.string(forKey: Self.fontKey),
           let saved = ScoreNumberFont(rawValue: raw) {
            numberFont = saved
        } else {
            numberFont = .rounded
        }
        if UserDefaults.standard.object(forKey: Self.chromeKey) != nil {
            chromeExpanded = UserDefaults.standard.bool(forKey: Self.chromeKey)
        } else {
            // First launch: show chrome so host can share the code, then user can tuck it away.
            chromeExpanded = true
        }
    }

    /// Apply remote theme/font (Watch → phone, or Host → Join over Bonjour).
    /// Local chrome expand/collapse is untouched. Never echoes back to Watch.
    func applyRemote(_ snapshot: ScoreDisplayPrefsSnapshot) {
        if numberTheme != snapshot.numberTheme {
            numberTheme = snapshot.numberTheme
        }
        if numberFont != snapshot.numberFont {
            numberFont = snapshot.numberFont
        }
    }

    /// Watch → phone path (one-way). Prefer `applyRemote` for new call sites.
    func applyFromWatch(_ snapshot: ScoreDisplayPrefsSnapshot) {
        applyRemote(snapshot)
    }
}
