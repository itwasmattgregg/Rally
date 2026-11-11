import Foundation
import Network
import Observation

/// Bonjour / Network.framework advertiser on the phone. Fans GameState to connected iPads.
@MainActor
@Observable
final class BoardAdvertiser {
    private(set) var isAdvertising = false
    private(set) var lastError: String?
    private(set) var peerCount = 0

    private var listener: NWListener?
    private var connections: [ObjectIdentifier: PeerConnection] = [:]
    private var authority: PhoneSessionAuthority?

    func start(authority: PhoneSessionAuthority) {
        self.authority = authority
        // Restart so the published name/TXT always match the on-screen code.
        stop()

        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            let listener = try NWListener(using: parameters)
            listener.service = NWListener.Service(
                name: RallyWire.serviceName(for: authority.sessionCode),
                type: RallyWire.bonjourType,
                txtRecord: txtRecord(for: authority)
            )

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch state {
                    case .ready:
                        self.isAdvertising = true
                        self.lastError = nil
                    case .failed(let error):
                        self.isAdvertising = false
                        self.lastError = error.localizedDescription
                    case .cancelled:
                        self.isAdvertising = false
                    default:
                        break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in
                    self?.accept(connection)
                }
            }

            listener.start(queue: .main)
            self.listener = listener
            authority.bootstrapHostIfNeeded()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for peer in connections.values {
            peer.cancel()
        }
        connections.removeAll()
        peerCount = 0
        isAdvertising = false
    }

    func broadcast(_ state: GameState) {
        refreshTXT()
        let envelope = RallyWire.Envelope(
            type: .update,
            protocolVersion: RallyWire.protocolVersion,
            sessionCode: authority?.sessionCode,
            gameId: state.gameId,
            state: state,
            reason: nil
        )
        guard let data = try? RallyWire.encode(envelope) else { return }
        let frame = RallyWire.frame(data)
        for peer in connections.values {
            peer.send(frame)
        }
    }

    private func accept(_ connection: NWConnection) {
        let peer = PeerConnection(connection: connection)
        let id = ObjectIdentifier(peer)
        connections[id] = peer
        peerCount = connections.count
        authority?.noteDisplayCount(peerCount)

        peer.onClosed = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.connections.removeValue(forKey: id)
                self.peerCount = self.connections.count
                self.authority?.noteDisplayCount(self.peerCount)
            }
        }

        peer.onFrames = { [weak self] frames in
            Task { @MainActor [weak self] in
                self?.handleIncoming(frames, from: peer)
            }
        }

        peer.start()

        if let authority {
            let hello = RallyWire.Envelope(
                type: .snapshot,
                protocolVersion: RallyWire.protocolVersion,
                sessionCode: authority.sessionCode,
                gameId: authority.state.gameId,
                state: authority.state,
                reason: nil
            )
            if let data = try? RallyWire.encode(hello) {
                peer.send(RallyWire.frame(data))
            }
        }
    }

    private func handleIncoming(_ frames: [Data], from peer: PeerConnection) {
        guard let authority else { return }
        for frame in frames {
            guard let envelope = try? RallyWire.decode(frame) else { continue }
            switch envelope.type {
            case .hello:
                let code = envelope.sessionCode ?? ""
                if !code.isEmpty && code.uppercased() != authority.sessionCode.uppercased() {
                    let reject = RallyWire.Envelope(
                        type: .reject,
                        protocolVersion: RallyWire.protocolVersion,
                        sessionCode: authority.sessionCode,
                        gameId: authority.state.gameId,
                        state: nil,
                        reason: "Wrong session code"
                    )
                    if let data = try? RallyWire.encode(reject) {
                        peer.send(RallyWire.frame(data))
                    }
                    peer.cancel()
                    return
                }
                let snap = RallyWire.Envelope(
                    type: .snapshot,
                    protocolVersion: RallyWire.protocolVersion,
                    sessionCode: authority.sessionCode,
                    gameId: authority.state.gameId,
                    state: authority.state,
                    reason: nil
                )
                if let data = try? RallyWire.encode(snap) {
                    peer.send(RallyWire.frame(data))
                }
            case .heartbeat:
                break
            default:
                break
            }
        }
    }

    private func refreshTXT() {
        guard let authority, let listener else { return }
        listener.service = NWListener.Service(
            name: RallyWire.serviceName(for: authority.sessionCode),
            type: RallyWire.bonjourType,
            txtRecord: txtRecord(for: authority)
        )
    }

    private func txtRecord(for authority: PhoneSessionAuthority) -> NWTXTRecord {
        var txt = NWTXTRecord()
        txt["v"] = "\(RallyWire.protocolVersion)"
        txt["gameId"] = authority.state.gameId
        txt["revision"] = "\(authority.state.revision)"
        txt["code"] = authority.sessionCode.uppercased()
        return txt
    }
}

/// Thin NWConnection wrapper with length-prefixed framing.
@MainActor
final class PeerConnection {
    private let connection: NWConnection
    private var buffer = Data()
    var onFrames: (([Data]) -> Void)?
    var onClosed: (() -> Void)?

    init(connection: NWConnection) {
        self.connection = connection
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                switch state {
                case .failed, .cancelled:
                    self?.onClosed?()
                default:
                    break
                }
            }
        }
        connection.start(queue: .main)
        receive()
    }

    func send(_ data: Data) {
        connection.send(content: data, completion: .contentProcessed { _ in })
    }

    func cancel() {
        connection.cancel()
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] content, _, isComplete, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let content {
                    self.buffer.append(content)
                    let frames = RallyWire.deframe(buffer: &self.buffer)
                    if !frames.isEmpty {
                        self.onFrames?(frames)
                    }
                }
                if isComplete || error != nil {
                    self.onClosed?()
                    self.connection.cancel()
                    return
                }
                self.receive()
            }
        }
    }
}
