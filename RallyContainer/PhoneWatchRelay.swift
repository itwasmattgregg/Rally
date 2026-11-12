import Foundation
import WatchConnectivity

/// Sendable slice of a WCSession dictionary for hopping onto the main actor.
nonisolated private struct IncomingWCPayload: Sendable {
    var kind: String?
    var eventData: Data?
    var stateData: Data?
    var prefsData: Data?

    init(from message: [String: Any]) {
        kind = message[RallyWC.kindKey] as? String
        eventData = message[RallyWC.eventKey] as? Data
        stateData = message[RallyWC.stateKey] as? Data
        prefsData = message[RallyWC.prefsKey] as? Data
    }
}

/// WCSession reply handlers are not Sendable; box for the MainActor hop only.
nonisolated private struct WCReplyHandler: @unchecked Sendable {
    let call: ([String: Any]) -> Void
}

/// Applies Watch → phone events for display / Bonjour fan-out.
/// Never pushes GameState or display prefs back to the Watch (one-way).
@MainActor
@Observable
final class PhoneWatchRelay: NSObject {
    private let authority: PhoneSessionAuthority
    var onStateChanged: ((GameState) -> Void)?
    /// Theme/font from Watch. Phone applies locally and must not echo back.
    var onDisplayPrefs: ((ScoreDisplayPrefsSnapshot) -> Void)?

    init(authority: PhoneSessionAuthority) {
        self.authority = authority
        super.init()
        activateIfPossible()
    }

    func activateIfPossible() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func handle(_ payload: IncomingWCPayload, reply: WCReplyHandler?) {
        // Events are the scoring path.
        if let data = payload.eventData,
           let event = try? JSONDecoder.rally.decode(ScoreEvent.self, from: data) {
            let state = authority.apply(event)
            onStateChanged?(state)
            // Ack only — do not include GameState or the Watch will fight itself.
            reply?.call([
                RallyWC.kindKey: RallyWC.kindAck,
                RallyWC.ackEventIdKey: event.eventId,
                RallyWC.revisionKey: state.revision
            ])
            return
        }

        // Optional one-way mirror (e.g. reset) for displays when no event was sent.
        if payload.kind == RallyWC.kindSnapshot || payload.stateData != nil,
           let data = payload.stateData,
           let state = try? JSONDecoder.rally.decode(GameState.self, from: data) {
            authority.adoptSnapshot(state)
            onStateChanged?(authority.state)
            reply?.call([RallyWC.kindKey: RallyWC.kindAck])
            return
        }

        // Shared theme/font from Watch — apply on phone only; never send prefs to Watch.
        if payload.kind == RallyWC.kindDisplayPrefs || payload.prefsData != nil,
           let data = payload.prefsData,
           let prefs = try? JSONDecoder.rally.decode(ScoreDisplayPrefsSnapshot.self, from: data) {
            onDisplayPrefs?(prefs)
            reply?.call([RallyWC.kindKey: RallyWC.kindAck])
            return
        }

        reply?.call([:])
    }

    private func noteDefaultSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        authority.noteWatchLink(
            watchAppInstalled: session.isWatchAppInstalled,
            reachable: session.isReachable
        )
    }
}

extension PhoneWatchRelay: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.noteDefaultSession()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.noteDefaultSession()
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.noteDefaultSession()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let payload = IncomingWCPayload(from: message)
        Task { @MainActor in
            self.handle(payload, reply: nil)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        let payload = IncomingWCPayload(from: message)
        let reply = WCReplyHandler(call: replyHandler)
        Task { @MainActor in
            self.handle(payload, reply: reply)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let payload = IncomingWCPayload(from: applicationContext)
        Task { @MainActor in
            self.handle(payload, reply: nil)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        let payload = IncomingWCPayload(from: userInfo)
        Task { @MainActor in
            self.handle(payload, reply: nil)
        }
    }
}
