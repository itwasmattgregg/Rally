import Foundation
import Observation

/// Watch-local display + crown prefs. Theme/font models match phone; crown is Watch-only.
/// Publishing to phone is one-way (never adopt phone prefs).
@Observable
final class WatchDisplayPreferences {
    private static let themeKey = "rally.watch.numberTheme"
    private static let fontKey = "rally.watch.numberFont"
    private static let crownKey = "rally.watch.crownAdjustsScore"

    private let defaults: UserDefaults
    private var onChange: ((ScoreDisplayPrefsSnapshot) -> Void)?

    var numberTheme: ScoreNumberTheme {
        didSet {
            defaults.set(numberTheme.rawValue, forKey: Self.themeKey)
            publishSharedPrefs()
        }
    }

    var numberFont: ScoreNumberFont {
        didSet {
            defaults.set(numberFont.rawValue, forKey: Self.fontKey)
            publishSharedPrefs()
        }
    }

    /// Digital Crown adjusts the active side score. Off by default to avoid pocket bumps.
    var crownAdjustsScore: Bool {
        didSet { defaults.set(crownAdjustsScore, forKey: Self.crownKey) }
    }

    var snapshot: ScoreDisplayPrefsSnapshot {
        ScoreDisplayPrefsSnapshot(numberTheme: numberTheme, numberFont: numberFont)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.themeKey),
           let saved = ScoreNumberTheme(rawValue: raw) {
            numberTheme = saved
        } else {
            numberTheme = .mintEmber
        }
        if let raw = defaults.string(forKey: Self.fontKey),
           let saved = ScoreNumberFont(rawValue: raw) {
            numberFont = saved
        } else {
            numberFont = .rounded
        }
        if defaults.object(forKey: Self.crownKey) != nil {
            crownAdjustsScore = defaults.bool(forKey: Self.crownKey)
        } else {
            crownAdjustsScore = false
        }
    }

    func bindPublisher(_ handler: @escaping (ScoreDisplayPrefsSnapshot) -> Void) {
        onChange = handler
        handler(snapshot)
    }

    private func publishSharedPrefs() {
        onChange?(snapshot)
    }
}
