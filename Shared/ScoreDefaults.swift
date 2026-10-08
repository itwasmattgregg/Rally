import Foundation

enum ScoreDefaults {
    /// On-watch App Group for the complication only (not phone sync).
    /// Set the same ID on the Watch app + Widget targets in Xcode.
    static let suiteName = "group.com.example.ScoreKeep"

    static let homeKey = "homeScore"
    static let awayKey = "awayScore"
    static let homeNameKey = "homeName"
    static let awayNameKey = "awayName"

    static var store: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func readScores() -> (home: Int, away: Int) {
        (store.integer(forKey: homeKey), store.integer(forKey: awayKey))
    }
}
