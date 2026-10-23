import Foundation

/// Watch → phone mutation when the companion is present.
struct ScoreEvent: Codable, Equatable, Identifiable, Sendable {
    enum Op: String, Codable, Sendable {
        case increment
        case decrement
        case undo
        case setLabel
        case start
        case end
    }

    var eventId: String
    var gameId: String
    var op: Op
    var sideId: String?
    var delta: Int?
    var label: String?
    var createdAt: Date

    var id: String { eventId }

    static func make(
        op: Op,
        gameId: String,
        sideId: String? = nil,
        delta: Int? = nil,
        label: String? = nil
    ) -> ScoreEvent {
        ScoreEvent(
            eventId: UUID().uuidString,
            gameId: gameId,
            op: op,
            sideId: sideId,
            delta: delta,
            label: label,
            createdAt: Date()
        )
    }
}

/// Short undo stack used by Watch (local) and phone (authority).
struct ScoreUndoStack: Sendable {
    private var events: [ScoreEvent] = []
    private let limit: Int

    init(limit: Int = 20) {
        self.limit = limit
    }

    var count: Int { events.count }

    mutating func push(_ event: ScoreEvent) {
        events.append(event)
        if events.count > limit {
            events.removeFirst(events.count - limit)
        }
    }

    mutating func pop() -> ScoreEvent? {
        events.popLast()
    }

    mutating func clear() {
        events.removeAll()
    }
}
