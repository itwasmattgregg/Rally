import Foundation
import Observation

/// Phone-side session authority for the Watch → display path.
/// Applies Watch events, owns revision, fans out to local displays.
@MainActor
@Observable
final class PhoneSessionAuthority {
    private(set) var state: GameState
    private(set) var sessionCode: String
    private(set) var isHosting = false
    private(set) var watchConnected = false
    private(set) var connectedDisplays = 0
    private(set) var statusMessage: String = "Waiting for Watch…"

    private var undoStack = ScoreUndoStack()
    private var appliedEventIds = Set<String>()

    init() {
        state = GameState.fresh()
        sessionCode = RallyWire.makeSessionCode()
    }

    func bootstrapHostIfNeeded() {
        guard !isHosting else { return }
        isHosting = true
        if state.status != .live {
            state.status = .live
        }
        statusMessage = "Hosting · code \(sessionCode)"
    }

    func rotateSessionCode() {
        sessionCode = RallyWire.makeSessionCode()
        statusMessage = "Hosting · code \(sessionCode)"
    }

    @discardableResult
    func apply(_ event: ScoreEvent) -> GameState {
        bootstrapHostIfNeeded()

        if appliedEventIds.contains(event.eventId) {
            return state
        }

        // Adopt Watch game id when the Watch starts a session or first score arrives.
        if state.gameId != event.gameId {
            state.gameId = event.gameId
            undoStack.clear()
            appliedEventIds.removeAll()
        }

        switch event.op {
        case .increment:
            let delta = event.delta ?? 1
            if let sideId = event.sideId {
                state.mutateScore(sideId: sideId, delta: abs(delta))
                undoStack.push(event)
            }
        case .decrement:
            let delta = event.delta ?? -1
            if let sideId = event.sideId {
                state.mutateScore(sideId: sideId, delta: -abs(delta))
                undoStack.push(event)
            }
        case .undo:
            if let previous = undoStack.pop() {
                switch previous.op {
                case .increment:
                    if let sideId = previous.sideId {
                        state.mutateScore(sideId: sideId, delta: -(previous.delta ?? 1))
                    }
                case .decrement:
                    if let sideId = previous.sideId {
                        state.mutateScore(sideId: sideId, delta: abs(previous.delta ?? 1))
                    }
                default:
                    break
                }
            }
        case .setLabel:
            if let sideId = event.sideId, let label = event.label {
                state.setLabel(sideId: sideId, label: label)
            }
        case .start:
            state.markStarted(eventId: event.eventId)
            statusMessage = "Live · code \(sessionCode)"
        case .end:
            state.markEnded(eventId: event.eventId)
            statusMessage = "Ended · code \(sessionCode)"
        }

        state.lastEventId = event.eventId
        appliedEventIds.insert(event.eventId)
        if appliedEventIds.count > 200 {
            appliedEventIds = Set(appliedEventIds.suffix(100))
        }
        watchConnected = true
        return state
    }

    func adoptSnapshot(_ snapshot: GameState) {
        bootstrapHostIfNeeded()
        state = snapshot
        watchConnected = true
        statusMessage = "Live · code \(sessionCode)"
    }

    func noteDisplayCount(_ count: Int) {
        connectedDisplays = count
    }

    /// - Parameters:
    ///   - watchAppInstalled: Watch companion is installed on the paired watch.
    ///   - reachable: WC interactive messaging is available right now.
    func noteWatchLink(watchAppInstalled: Bool, reachable: Bool) {
        watchConnected = watchAppInstalled && reachable
        guard isHosting else { return }
        if !watchAppInstalled {
            statusMessage = "Waiting for Watch · code \(sessionCode)"
        } else if reachable {
            statusMessage = "Watch linked · code \(sessionCode)"
        } else {
            statusMessage = "Watch out of range · code \(sessionCode)"
        }
    }
}
