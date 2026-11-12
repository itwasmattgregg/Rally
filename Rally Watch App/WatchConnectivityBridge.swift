import Foundation
import WatchConnectivity

/// One-way Watch → phone relay. The Watch never applies phone GameState.
@MainActor
@Observable
final class WatchConnectivityBridge: NSObject {
    private(set) var isReachable = false
    private(set) var isActivated = false
    private(set) var isCompanionAppInstalled = false
    private(set) var lastError: String?

    /// Delivery receipt only (eventId, revision). Never carries board mutations back.
    var onAck: ((String, UInt64) -> Void)?

    var canRelay: Bool { isActivated && isCompanionAppInstalled }

    /// Retained so theme/font can flush once WC activates (never read from phone).
    private var pendingDisplayPrefs: ScoreDisplayPrefsSnapshot?

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

    /// Send a score mutation to the phone. Phone may ack; Watch ignores any board payload.
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
                    let eventId = reply[RallyWC.ackEventIdKey] as? String
                    let revision = reply[RallyWC.revisionKey] as? UInt64 ?? 0
                    Task { @MainActor [weak self] in
                        self?.handleAck(eventId: eventId, revision: revision)
                    }
                }, errorHandler: { [weak self] error in
                    let message = error.localizedDescription
                    Task { @MainActor [weak self] in
                        self?.lastError = message
                        self?.queueEvent(data)
                    }
                })
            } else {
                queueEvent(data)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Rare catch-up for displays (e.g. reset). Still one-way; Watch does not read replies as state.
    func publishDisplayMirror(_ state: GameState) {
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
            let nsError = error as NSError
            if nsError.domain == WCErrorDomain, nsError.code == 7018 {
                isCompanionAppInstalled = false
                return
            }
            lastError = error.localizedDescription
        }
    }

    /// One-way Watch → phone theme/font. Phone applies locally and must never echo prefs back.
    func publishDisplayPrefs(_ snapshot: ScoreDisplayPrefsSnapshot) {
        pendingDisplayPrefs = snapshot
        flushPendingDisplayPrefs()
    }

    private func flushPendingDisplayPrefs() {
        guard let snapshot = pendingDisplayPrefs else { return }
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        refreshCompanionState()
        guard isCompanionAppInstalled else { return }
        do {
            let data = try JSONEncoder.rally.encode(snapshot)
            let payload: [String: Any] = [
                RallyWC.kindKey: RallyWC.kindDisplayPrefs,
                RallyWC.prefsKey: data
            ]
            if session.isReachable {
                session.sendMessage(payload, replyHandler: { _ in }, errorHandler: { [weak self] error in
                    let message = error.localizedDescription
                    Task { @MainActor [weak self] in
                        self?.lastError = message
                        self?.queueDisplayPrefs(data)
                    }
                })
            } else {
                queueDisplayPrefs(data)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Queued delivery so prefs do not clobber a pending score applicationContext.
    private func queueDisplayPrefs(_ prefsData: Data) {
        WCSession.default.transferUserInfo([
            RallyWC.kindKey: RallyWC.kindDisplayPrefs,
            RallyWC.prefsKey: prefsData
        ])
    }

    private func queueEvent(_ eventData: Data) {
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

    private func handleAck(eventId: String?, revision: UInt64) {
        // Intentionally ignore any `state` / snapshot keys — one-way scoring.
        if let eventId {
            onAck?(eventId, revision)
        }
        refreshCompanionState()
    }
}

extension WatchConnectivityBridge: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let message = error?.localizedDescription
        Task { @MainActor in
            self.refreshCompanionState()
            if let message {
                self.lastError = message
            }
            self.flushPendingDisplayPrefs()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshCompanionState()
            self.flushPendingDisplayPrefs()
        }
    }

    nonisolated func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshCompanionState()
            self.flushPendingDisplayPrefs()
        }
    }

    // Phone should not drive the Watch board. Ignore inbound WC payloads.
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {}

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        replyHandler([:])
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {}
}
