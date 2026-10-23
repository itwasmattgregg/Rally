import Foundation
import WatchConnectivity

/// Best-effort Watch → phone relay. Scoring stays local if the companion is absent.
@MainActor
@Observable
final class WatchConnectivityBridge: NSObject {
    private(set) var isReachable = false
    private(set) var isActivated = false
    /// False when the iOS companion isn't installed on the paired phone (common in Simulator
    /// if Rally wasn't installed on that iPhone, or Watch wasn't embedded/paired).
    private(set) var isCompanionAppInstalled = false
    private(set) var lastError: String?

    var onAck: ((String, UInt64) -> Void)?
    var onSnapshot: ((GameState) -> Void)?

    /// True when WC can usefully talk to the phone companion.
    var canRelay: Bool { isActivated && isCompanionAppInstalled }

    override init() {
        super.init()
        activateIfPossible()
    }

    func activateIfPossible() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func refreshCompanionState() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        isActivated = session.activationState == .activated
        isReachable = session.isReachable
        if #available(watchOS 6.0, *) {
            isCompanionAppInstalled = session.isCompanionAppInstalled
        } else {
            isCompanionAppInstalled = true
        }
    }

    func send(_ event: ScoreEvent) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        refreshCompanionState()
        guard isCompanionAppInstalled else { return }

        do {
            let data = try JSONEncoder.rally.encode(event)
            let payload: [String: Any] = [
                RallyWC.kindKey: RallyWC.kindEvent,
                RallyWC.eventKey: data
            ]

            if session.isReachable {
                session.sendMessage(payload, replyHandler: { [weak self] reply in
                    Task { @MainActor in
                        self?.handleReply(reply)
                    }
                }, errorHandler: { [weak self] error in
                    Task { @MainActor in
                        self?.lastError = error.localizedDescription
                        self?.pushContext(with: data)
                    }
                })
            } else {
                pushContext(with: data)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func publishSnapshot(_ state: GameState) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        refreshCompanionState()
        guard isCompanionAppInstalled else { return }
        do {
            let data = try JSONEncoder.rally.encode(state)
            try session.updateApplicationContext([
                RallyWC.kindKey: RallyWC.kindSnapshot,
                RallyWC.stateKey: data
            ])
        } catch {
            // 7018 = companion not installed; don't surface as a hard failure while scoring alone.
            let nsError = error as NSError
            if nsError.domain == WCErrorDomain, nsError.code == 7018 {
                isCompanionAppInstalled = false
                return
            }
            lastError = error.localizedDescription
        }
    }

    func requestSync() {
        guard canRelay, WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([RallyWC.kindKey: RallyWC.kindRequestSync], replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.handleReply(reply)
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                self?.lastError = error.localizedDescription
            }
        })
    }

    private func pushContext(with eventData: Data) {
        refreshCompanionState()
        guard isCompanionAppInstalled else { return }
        do {
            try WCSession.default.updateApplicationContext([
                RallyWC.kindKey: RallyWC.kindEvent,
                RallyWC.eventKey: eventData
            ])
        } catch {
            let nsError = error as NSError
            if nsError.domain == WCErrorDomain, nsError.code == 7018 {
                isCompanionAppInstalled = false
                return
            }
            lastError = error.localizedDescription
        }
    }

    private func handleReply(_ reply: [String: Any]) {
        if let kind = reply[RallyWC.kindKey] as? String, kind == RallyWC.kindSnapshot,
           let data = reply[RallyWC.stateKey] as? Data,
           let state = try? JSONDecoder.rally.decode(GameState.self, from: data) {
            onSnapshot?(state)
            return
        }
        if let eventId = reply[RallyWC.ackEventIdKey] as? String,
           let revision = reply[RallyWC.revisionKey] as? UInt64 {
            onAck?(eventId, revision)
        }
        if let data = reply[RallyWC.stateKey] as? Data,
           let state = try? JSONDecoder.rally.decode(GameState.self, from: data) {
            onSnapshot?(state)
        }
    }
}

extension WatchConnectivityBridge: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.refreshCompanionState()
            if let error {
                self.lastError = error.localizedDescription
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshCompanionState()
        }
    }

    nonisolated func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshCompanionState()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleReply(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            self.handleReply(message)
            replyHandler([:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.handleReply(applicationContext)
        }
    }
}
