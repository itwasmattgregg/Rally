import Foundation
import WatchConnectivity

/// Applies Watch → phone events for display / Bonjour fan-out.
/// Never pushes GameState back to the Watch (scoring is one-way).
@MainActor
@Observable
final class PhoneWatchRelay: NSObject {
    private let authority: PhoneSessionAuthority
    var onStateChanged: ((GameState) -> Void)?

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

    private func handle(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        let kind = message[RallyWC.kindKey] as? String

        // Events are the scoring path.
        if let data = message[RallyWC.eventKey] as? Data,
           let event = try? JSONDecoder.rally.decode(ScoreEvent.self, from: data) {
            let state = authority.apply(event)
            onStateChanged?(state)
            // Ack only — do not include GameState or the Watch will fight itself.
            replyHandler?([
                RallyWC.kindKey: RallyWC.kindAck,
                RallyWC.ackEventIdKey: event.eventId,
                RallyWC.revisionKey: state.revision
            ])
            return
        }

        // Optional one-way mirror (e.g. reset) for displays when no event was sent.
        if kind == RallyWC.kindSnapshot || message[RallyWC.stateKey] != nil,
           let data = message[RallyWC.stateKey] as? Data,
           let state = try? JSONDecoder.rally.decode(GameState.self, from: data) {
            authority.adoptSnapshot(state)
            onStateChanged?(authority.state)
            replyHandler?([RallyWC.kindKey: RallyWC.kindAck])
            return
        }

        replyHandler?([:])
    }
}

extension PhoneWatchRelay: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.noteSession(session)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.noteSession(session)
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.noteSession(session)
        }
    }

    @MainActor
    private func noteSession(_ session: WCSession) {
        authority.noteWatchLink(
            watchAppInstalled: session.isWatchAppInstalled,
            reachable: session.isReachable
        )
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handle(message, replyHandler: nil)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            self.handle(message, replyHandler: replyHandler)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.handle(applicationContext, replyHandler: nil)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        Task { @MainActor in
            self.handle(userInfo, replyHandler: nil)
        }
    }
}
