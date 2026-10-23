import Foundation

/// Exactly two unbounded integer sides. No win rules / caps.
struct GameState: Codable, Equatable, Sendable {
    enum Status: String, Codable, Sendable {
        case live
        case ended
    }

    struct Side: Codable, Equatable, Identifiable, Sendable {
        var id: String
        var label: String
        var score: Int

        static let sideA = "a"
        static let sideB = "b"
    }

    var gameId: String
    var revision: UInt64
    var status: Status
    var sides: [Side]
    var lastEventId: String?
    var updatedAt: Date

    var sideA: Side {
        sides.first(where: { $0.id == Side.sideA }) ?? Side(id: Side.sideA, label: "HOME", score: 0)
    }

    var sideB: Side {
        sides.first(where: { $0.id == Side.sideB }) ?? Side(id: Side.sideB, label: "AWAY", score: 0)
    }

    var summaryLine: String {
        "\(sideA.score)–\(sideB.score)"
    }

    static func fresh(
        gameId: String = UUID().uuidString,
        labelA: String = "HOME",
        labelB: String = "AWAY"
    ) -> GameState {
        GameState(
            gameId: gameId,
            revision: 0,
            status: .live,
            sides: [
                Side(id: Side.sideA, label: labelA, score: 0),
                Side(id: Side.sideB, label: labelB, score: 0)
            ],
            lastEventId: nil,
            updatedAt: Date()
        )
    }

    mutating func mutateScore(sideId: String, delta: Int) {
        guard let index = sides.firstIndex(where: { $0.id == sideId }) else { return }
        sides[index].score = max(0, sides[index].score + delta)
        bumpRevision()
    }

    mutating func setLabel(sideId: String, label: String) {
        guard let index = sides.firstIndex(where: { $0.id == sideId }) else { return }
        sides[index].label = label
        bumpRevision()
    }

    mutating func replace(with other: GameState) {
        self = other
    }

    mutating func markEnded(eventId: String?) {
        status = .ended
        lastEventId = eventId
        bumpRevision()
    }

    mutating func markStarted(eventId: String?) {
        status = .live
        lastEventId = eventId
        bumpRevision()
    }

    private mutating func bumpRevision() {
        revision &+= 1
        updatedAt = Date()
    }
}
