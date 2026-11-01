import Foundation

enum RallyWire {
    static let protocolVersion = 1
    /// Bonjour service type for phone advertiser / iPad browser.
    static let bonjourType = "_rallyboard._tcp"
    static let bonjourDomain = "local."
    /// Service name prefix — iPad parses the code from `Rally-ABCD`.
    static let serviceNamePrefix = "Rally-"

    enum MessageType: String, Codable, Sendable {
        case hello
        case snapshot
        case update
        case heartbeat
        case reject
    }

    struct Envelope: Codable, Sendable {
        var type: MessageType
        var protocolVersion: Int
        var sessionCode: String?
        var gameId: String?
        var state: GameState?
        var reason: String?
    }

    /// 4-character join code shown on phone + matched from Bonjour name/TXT.
    static func makeSessionCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<4).map { _ in alphabet.randomElement()! })
    }

    static func serviceName(for code: String) -> String {
        "\(serviceNamePrefix)\(code.uppercased())"
    }

    /// Prefer code embedded in the Bonjour service name; fall back to TXT.
    static func code(fromServiceName name: String, txtCode: String?) -> String {
        if name.uppercased().hasPrefix(serviceNamePrefix.uppercased()) {
            let suffix = String(name.dropFirst(serviceNamePrefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            if suffix.count == 4 { return suffix }
        }
        return (txtCode ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func encode(_ envelope: Envelope) throws -> Data {
        try JSONEncoder.rally.encode(envelope)
    }

    static func decode(_ data: Data) throws -> Envelope {
        try JSONDecoder.rally.decode(Envelope.self, from: data)
    }

    /// Length-prefixed JSON frames over NWConnection.
    static func frame(_ payload: Data) -> Data {
        var length = UInt32(payload.count).bigEndian
        var out = Data(bytes: &length, count: 4)
        out.append(payload)
        return out
    }

    static func deframe(buffer: inout Data) -> [Data] {
        var frames: [Data] = []
        while buffer.count >= 4 {
            let length = Int(buffer.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
            guard length >= 0, buffer.count >= 4 + length else { break }
            let payload = buffer.subdata(in: 4..<(4 + length))
            buffer.removeSubrange(0..<(4 + length))
            frames.append(payload)
        }
        return frames
    }
}

extension JSONEncoder {
    static let rally: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let rally: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

/// WatchConnectivity dictionary keys (small payloads).
enum RallyWC {
    static let kindKey = "kind"
    static let eventKey = "event"
    static let stateKey = "state"
    static let ackEventIdKey = "ackEventId"
    static let revisionKey = "revision"
    static let phoneReachableKey = "phoneReachable"

    static let kindEvent = "scoreEvent"
    static let kindAck = "scoreAck"
    static let kindSnapshot = "snapshot"
    static let kindRequestSync = "requestSync"
}
