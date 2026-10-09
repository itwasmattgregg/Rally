import Foundation
import Observation

#if canImport(WidgetKit)
import WidgetKit
#endif

@Observable
final class ScoreBoard {
    var homeName: String {
        didSet { persist() }
    }

    var awayName: String {
        didSet { persist() }
    }

    var homeScore: Int {
        didSet { persist() }
    }

    var awayScore: Int {
        didSet { persist() }
    }

    private let maxScore = 999
    private let defaults: UserDefaults

    init(suiteName: String = ScoreDefaults.suiteName) {
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
        homeName = defaults.string(forKey: ScoreDefaults.homeNameKey) ?? "HOME"
        awayName = defaults.string(forKey: ScoreDefaults.awayNameKey) ?? "AWAY"
        homeScore = defaults.integer(forKey: ScoreDefaults.homeKey)
        awayScore = defaults.integer(forKey: ScoreDefaults.awayKey)
    }

    func bumpHome() {
        homeScore = min(homeScore + 1, maxScore)
    }

    func bumpAway() {
        awayScore = min(awayScore + 1, maxScore)
    }

    func dropHome() {
        homeScore = max(homeScore - 1, 0)
    }

    func dropAway() {
        awayScore = max(awayScore - 1, 0)
    }

    func reset() {
        homeScore = 0
        awayScore = 0
    }

    var summaryLine: String {
        "\(homeScore)–\(awayScore)"
    }

    private func persist() {
        defaults.set(homeName, forKey: ScoreDefaults.homeNameKey)
        defaults.set(awayName, forKey: ScoreDefaults.awayNameKey)
        defaults.set(homeScore, forKey: ScoreDefaults.homeKey)
        defaults.set(awayScore, forKey: ScoreDefaults.awayKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "ScoreWidget")
        #endif
    }
}
