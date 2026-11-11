import Foundation
import Network
import Observation

/// iPad (or any spectator) joins a phone-hosted Rally board over Bonjour / Network.framework.
@MainActor
@Observable
final class BoardBrowser {
    struct NearbyBoard: Identifiable, Equatable {
        var id: String { code.isEmpty ? name : code }
        var name: String
        var code: String
        var gameId: String
        var endpoint: NWEndpoint
    }

    private(set) var nearby: [NearbyBoard] = []
    private(set) var state: GameState?
    private(set) var isBrowsing = false
    private(set) var isConnected = false
    private(set) var isReconnecting = false
    private(set) var statusMessage = "Looking for boards…"
    private(set) var lastError: String?

    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var buffer = Data()
    private var preferredCode: String?
    private var preferredGameId: String?
    private var heartbeat: Timer?
    private var reconnectTask: Task<Void, Never>?

    func startBrowsing() {
        stopBrowsing()
        let descriptor = NWBrowser.Descriptor.bonjour(type: RallyWire.bonjourType, domain: RallyWire.bonjourDomain)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: descriptor, using: parameters)

        browser.stateUpdateHandler = { [weak self] browseState in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch browseState {
                case .ready:
                    self.isBrowsing = true
                    self.lastError = nil
                    self.statusMessage = "Looking for boards…"
                case .failed(let error):
                    self.isBrowsing = false
                    self.lastError = error.localizedDescription
                default:
                    break
                }
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor [weak self] in
                self?.ingest(results)
            }
        }

        browser.start(queue: .main)
        self.browser = browser
        statusMessage = "Looking for boards…"
    }

    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        isBrowsing = false
        nearby = []
    }

    func join(code: String) {
        preferredCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let match = nearby.first(where: { $0.code == preferredCode }) {
            connect(to: match)
            return
        }
        statusMessage = "Waiting for code \(preferredCode ?? "")…"
        if !isBrowsing { startBrowsing() }
    }

    func join(_ board: NearbyBoard) {
        preferredCode = board.code
        preferredGameId = board.gameId
        connect(to: board)
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        heartbeat?.invalidate()
        heartbeat = nil
        connection?.cancel()
        connection = nil
        isConnected = false
        isReconnecting = false
        buffer = Data()
        statusMessage = "Disconnected"
    }

    private func ingest(_ results: Set<NWBrowser.Result>) {
        var byCode: [String: NearbyBoard] = [:]
        for result in results {
            guard case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint else { continue }
            var txtCode: String?
            var gameId = ""
            if case let .bonjour(txt) = result.metadata {
                txtCode = txt["code"]
                gameId = txt["gameId"] ?? ""
            }
            let code = RallyWire.code(fromServiceName: name, txtCode: txtCode)
            guard code.count == 4 else { continue }
            // Newest browse result wins for a given code (drops stale TXT ghosts).
            byCode[code] = NearbyBoard(
                name: RallyWire.serviceName(for: code),
                code: code,
                gameId: gameId,
                endpoint: result.endpoint
            )
        }
        nearby = byCode.values.sorted { $0.code < $1.code }

        if let preferredCode,
           let match = nearby.first(where: { $0.code == preferredCode }) {
            connect(to: match)
        } else if let preferredGameId,
                  let match = nearby.first(where: { $0.gameId == preferredGameId }) {
            connect(to: match)
        }
    }

    private func connect(to board: NearbyBoard) {
        // Avoid tearing down a good live connection to the same board.
        if isConnected, preferredCode == board.code, connection != nil { return }

        disconnect()
        preferredCode = board.code
        preferredGameId = board.gameId
        isReconnecting = false
        statusMessage = "Connecting to \(board.code)…"

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let connection = NWConnection(to: board.endpoint, using: parameters)
        self.connection = connection

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.handleConnectionState(state, board: board)
            }
        }
        connection.start(queue: .main)
        receive()
    }

    private func handleConnectionState(_ state: NWConnection.State, board: NearbyBoard) {
        switch state {
        case .ready:
            isConnected = true
            isReconnecting = false
            statusMessage = "Connected · \(board.code)"
            sendHello(code: board.code)
            startHeartbeat()
        case .failed(let error):
            lastError = error.localizedDescription
            scheduleReconnect()
        case .cancelled:
            isConnected = false
        default:
            break
        }
    }

    private func sendHello(code: String) {
        let envelope = RallyWire.Envelope(
            type: .hello,
            protocolVersion: RallyWire.protocolVersion,
            sessionCode: code,
            gameId: preferredGameId,
            state: nil,
            reason: nil
        )
        guard let data = try? RallyWire.encode(envelope) else { return }
        connection?.send(content: RallyWire.frame(data), completion: .contentProcessed { _ in })
    }

    private func startHeartbeat() {
        heartbeat?.invalidate()
        heartbeat = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sendHeartbeat()
            }
        }
    }

    private func sendHeartbeat() {
        let envelope = RallyWire.Envelope(
            type: .heartbeat,
            protocolVersion: RallyWire.protocolVersion,
            sessionCode: preferredCode,
            gameId: preferredGameId,
            state: nil,
            reason: nil
        )
        guard let data = try? RallyWire.encode(envelope) else { return }
        connection?.send(content: RallyWire.frame(data), completion: .contentProcessed { _ in })
    }

    private func scheduleReconnect() {
        guard preferredCode != nil || preferredGameId != nil else { return }
        isConnected = false
        isReconnecting = true
        statusMessage = "Reconnecting…"
        reconnectTask?.cancel()
        reconnectTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            startBrowsing()
        }
    }

    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] content, _, isComplete, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let content {
                    self.buffer.append(content)
                    for frame in RallyWire.deframe(buffer: &self.buffer) {
                        self.handleFrame(frame)
                    }
                }
                if isComplete || error != nil {
                    self.scheduleReconnect()
                    return
                }
                self.receive()
            }
        }
    }

    private func handleFrame(_ data: Data) {
        guard let envelope = try? RallyWire.decode(data) else { return }
        switch envelope.type {
        case .snapshot, .update:
            if let state = envelope.state {
                self.state = state
                preferredGameId = state.gameId
                statusMessage = isReconnecting ? "Reconnected" : "Live"
                isReconnecting = false
            }
        case .reject:
            lastError = envelope.reason ?? "Rejected"
            statusMessage = lastError ?? "Rejected"
            disconnect()
        default:
            break
        }
    }
}
