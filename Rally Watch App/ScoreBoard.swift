import Foundation
import Observation

#if canImport(WidgetKit)
import WidgetKit
#endif

/// Watch is the sole scorer. Phone (if installed) is a one-way display sink — never writes back.
@Observable
final class ScoreBoard {
    private(set) var state: GameState
    private(set) var canUndo = false
    /// Companion is installed but WC reports not reachable.
    private(set) var phoneOutOfRange = false
    /// Paired phone doesn't have the iOS Rally app (or Simulator counterpart link isn't set up).
    private(set) var phoneAppMissing = false

    private var undoStack = ScoreUndoStack()
    private let defaults: UserDefaults
    private let bridge: WatchConnectivityBridge

    var homeName: String {
        get { state.sideA.label }
        set { setLabel(sideId: GameState.Side.sideA, label: newValue) }
    }

    var awayName: String {
        get { state.sideB.label }
        set { setLabel(sideId: GameState.Side.sideB, label: newValue) }
    }

    var homeScore: Int { state.sideA.score }
    var awayScore: Int { state.sideB.score }

    var summaryLine: String { state.summaryLine }

    init(suiteName: String? = nil, bridge: WatchConnectivityBridge? = nil) {
        let resolvedSuite = suiteName ?? ScoreDefaults.suiteName
        defaults = UserDefaults(suiteName: resolvedSuite) ?? .standard
        let resolvedBridge = bridge ?? WatchConnectivityBridge()
        self.bridge = resolvedBridge

        let labelA = defaults.string(forKey: ScoreDefaults.homeNameKey) ?? "HOME"
        let labelB = defaults.string(forKey: ScoreDefaults.awayNameKey) ?? "AWAY"
        var fresh = GameState.fresh(labelA: labelA, labelB: labelB)
        fresh.sides[0].score = max(0, defaults.integer(forKey: ScoreDefaults.homeKey))
        fresh.sides[1].score = max(0, defaults.integer(forKey: ScoreDefaults.awayKey))
        state = fresh

        // Acks are delivery receipts only — never apply phone GameState onto the Watch board.
        resolvedBridge.onAck = { [weak self] _, _ in
            self?.refreshReachability()
        }
        refreshReachability()
    }

    func bumpHome() { applyScore(sideId: GameState.Side.sideA, delta: 1) }
    func bumpAway() { applyScore(sideId: GameState.Side.sideB, delta: 1) }
    func dropHome() { applyScore(sideId: GameState.Side.sideA, delta: -1) }
    func dropAway() { applyScore(sideId: GameState.Side.sideB, delta: -1) }

    func undo() {
        guard let previous = undoStack.pop() else { return }
        canUndo = undoStack.count > 0

        switch previous.op {
        case .increment:
            if let sideId = previous.sideId {
                state.mutateScore(sideId: sideId, delta: -(previous.delta ?? 1))
            }
        case .decrement:
            if let sideId = previous.sideId {
                state.mutateScore(sideId: sideId, delta: abs(previous.delta ?? 1))
            }
        case .setLabel, .undo, .start, .end:
            break
        }
        state.lastEventId = previous.eventId
        persist()
        relay(ScoreEvent.make(op: .undo, gameId: state.gameId))
    }

    func reset() {
        let labels = (state.sideA.label, state.sideB.label)
        state = GameState.fresh(gameId: state.gameId, labelA: labels.0, labelB: labels.1)
        undoStack.clear()
        canUndo = false
        persist()
        // Catch-up mirror for displays (one-way); no event type for full reset in v1.
        bridge.publishDisplayMirror(state)
        refreshReachability()
    }

    func noteSessionStarted() {
        let event = ScoreEvent.make(op: .start, gameId: state.gameId)
        state.markStarted(eventId: event.eventId)
        persist()
        relay(event)
    }

    func noteSessionEnded() {
        let event = ScoreEvent.make(op: .end, gameId: state.gameId)
        state.markEnded(eventId: event.eventId)
        persist()
        relay(event)
    }

    func refreshReachability() {
        bridge.refreshCompanionState()
        phoneAppMissing = bridge.isActivated && !bridge.isCompanionAppInstalled
        phoneOutOfRange = bridge.canRelay && !bridge.isReachable
    }

    /// One-way theme/font push for phone/iPad displays. Never reads prefs back from phone.
    func publishDisplayPrefs(_ snapshot: ScoreDisplayPrefsSnapshot) {
        bridge.publishDisplayPrefs(snapshot)
        refreshReachability()
    }

    private func setLabel(sideId: String, label: String) {
        state.setLabel(sideId: sideId, label: label)
        persist()
        relay(ScoreEvent.make(op: .setLabel, gameId: state.gameId, sideId: sideId, label: label))
    }

    private func applyScore(sideId: String, delta: Int) {
        let op: ScoreEvent.Op = delta >= 0 ? .increment : .decrement
        let event = ScoreEvent.make(op: op, gameId: state.gameId, sideId: sideId, delta: delta)
        state.mutateScore(sideId: sideId, delta: delta)
        state.lastEventId = event.eventId
        undoStack.push(event)
        canUndo = true
        persist()
        relay(event)
    }

    private func relay(_ event: ScoreEvent) {
        bridge.send(event)
        refreshReachability()
    }

    private func persist() {
        defaults.set(state.sideA.label, forKey: ScoreDefaults.homeNameKey)
        defaults.set(state.sideB.label, forKey: ScoreDefaults.awayNameKey)
        defaults.set(state.sideA.score, forKey: ScoreDefaults.homeKey)
        defaults.set(state.sideB.score, forKey: ScoreDefaults.awayKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "RallyWidget")
        #endif
    }
}
