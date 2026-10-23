import Foundation
import Observation

#if canImport(WidgetKit)
import WidgetKit
#endif

@Observable
final class ScoreBoard {
    private(set) var state: GameState
    private(set) var canUndo = false
    private(set) var phoneOutOfRange = false

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

        resolvedBridge.onAck = { [weak self] eventId, revision in
            self?.applyAck(eventId: eventId, revision: revision)
        }
        resolvedBridge.onSnapshot = { [weak self] snapshot in
            self?.adoptPhoneSnapshot(snapshot)
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

        // Invert the last applied score mutation locally.
        switch previous.op {
        case .increment:
            if let sideId = previous.sideId {
                state.mutateScore(sideId: sideId, delta: -(previous.delta ?? 1))
            }
        case .decrement:
            if let sideId = previous.sideId {
                state.mutateScore(sideId: sideId, delta: abs(previous.delta ?? 1))
            }
        case .setLabel:
            // Labels are not on the undo stack for v1 taps; ignore.
            break
        case .undo, .start, .end:
            break
        }
        state.lastEventId = previous.eventId
        persist()

        let event = ScoreEvent.make(op: .undo, gameId: state.gameId)
        bridge.send(event)
        bridge.publishSnapshot(state)
        refreshReachability()
    }

    func reset() {
        let labels = (state.sideA.label, state.sideB.label)
        state = GameState.fresh(gameId: state.gameId, labelA: labels.0, labelB: labels.1)
        undoStack.clear()
        canUndo = false
        persist()
        bridge.publishSnapshot(state)
    }

    func noteSessionStarted() {
        let event = ScoreEvent.make(op: .start, gameId: state.gameId)
        state.markStarted(eventId: event.eventId)
        persist()
        bridge.send(event)
        bridge.publishSnapshot(state)
    }

    func noteSessionEnded() {
        let event = ScoreEvent.make(op: .end, gameId: state.gameId)
        state.markEnded(eventId: event.eventId)
        persist()
        bridge.send(event)
        bridge.publishSnapshot(state)
    }

    func refreshReachability() {
        phoneOutOfRange = bridge.isActivated && !bridge.isReachable
    }

    private func setLabel(sideId: String, label: String) {
        state.setLabel(sideId: sideId, label: label)
        persist()
        let event = ScoreEvent.make(op: .setLabel, gameId: state.gameId, sideId: sideId, label: label)
        bridge.send(event)
        bridge.publishSnapshot(state)
    }

    private func applyScore(sideId: String, delta: Int) {
        let op: ScoreEvent.Op = delta >= 0 ? .increment : .decrement
        let event = ScoreEvent.make(op: op, gameId: state.gameId, sideId: sideId, delta: delta)
        state.mutateScore(sideId: sideId, delta: delta)
        state.lastEventId = event.eventId
        undoStack.push(event)
        canUndo = true
        persist()
        bridge.send(event)
        bridge.publishSnapshot(state)
        refreshReachability()
    }

    private func applyAck(eventId: String, revision: UInt64) {
        if state.lastEventId == eventId || revision >= state.revision {
            state.revision = max(state.revision, revision)
        }
        refreshReachability()
    }

    private func adoptPhoneSnapshot(_ snapshot: GameState) {
        // Phone is authority when companion is in the loop; adopt if same game or phone is ahead.
        if snapshot.gameId == state.gameId || snapshot.revision > state.revision {
            state = snapshot
            persist()
        }
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
