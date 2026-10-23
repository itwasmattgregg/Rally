import Foundation
import WatchConnectivity

/// Receives WatchConnectivity events and feeds the phone session authority.
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

        if kind == RallyWC.kindRequestSync {
            replyWithSnapshot(replyHandler)
            return
        }

        if kind == RallyWC.kindSnapshot || message[RallyWC.stateKey] != nil,
           let data = message[RallyWC.stateKey] as? Data,
           let state = try? JSONDecoder.rally.decode(GameState.self, from: data) {
            authority.adoptSnapshot(state)
            onStateChanged?(authority.state)
            replyWithSnapshot(replyHandler)
            return
        }

        if let data = message[RallyWC.eventKey] as? Data,
           let event = try? JSONDecoder.rally.decode(ScoreEvent.self, from: data) {
            let state = authority.apply(event)
            onStateChanged?(state)
            var reply: [String: Any] = [
                RallyWC.kindKey: RallyWC.kindAck,
                RallyWC.ackEventIdKey: event.eventId,
                RallyWC.revisionKey: state.revision
            ]
            if let encoded = try? JSONEncoder.rally.encode(state) {
                reply[RallyWC.stateKey] = encoded
            }
            replyHandler?(reply)
            return
        }

        replyHandler?([:])
    }

    private func replyWithSnapshot(_ replyHandler: (([String: Any]) -> Void)?) {
        guard let encoded = try? JSONEncoder.rally.encode(authority.state) else {
            replyHandler?([:])
            return
        }
        replyHandler?([
            RallyWC.kindKey: RallyWC.kindSnapshot,
            RallyWC.stateKey: encoded,
            RallyWC.revisionKey: authority.state.revision
        ])
    }
}

extension PhoneWatchRelay: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.authority.noteWatchReachable(session.isReachable)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.authority.noteWatchReachable(session.isReachable)
        }
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
