import AVFoundation
import UIKit

/// Keeps the phone Host process alive while locked / backgrounded so
/// WatchConnectivity can apply scores and Bonjour can fan out to iPads.
///
/// Strategy (court Host only):
/// 1. Silent looping playback under the `audio` background mode — sustained
///    keepalive for match-length sessions (beginBackgroundTask alone expires
///    in ~30s and is not enough).
/// 2. Refresh `beginBackgroundTask` on each WC wake / fan-out so brief
///    system wakes still get a lease even if audio was interrupted.
///
/// Stop when leaving Host mode. See `internal/locked-phone-court-host.md`.
@MainActor
final class CourtBackgroundHost {
    private var task = UIBackgroundTaskIdentifier.invalid
    private var player: AVAudioPlayer?
    private var interruptionObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?
    private(set) var isHosting = false

    /// Begin sustained keepalive for an active Host session.
    func start() {
        isHosting = true
        activateAudioSession()
        startSilentPlayback()
        observeAudioLifecycle()
        extend(reason: "Rally host session start")
    }

    /// Tear down keepalive when Host ends or the app leaves court Host mode.
    func stop() {
        isHosting = false
        end()
        tearDownAudio()
    }

    /// Call when hosting starts, when entering background, and on each WC /
    /// score fan-out. Refreshes the short system background-task lease.
    func extend(reason: String = "Rally court relay") {
        guard isHosting else { return }

        if task != .invalid {
            // End + begin keeps us in the latest budget after a WC wake.
            UIApplication.shared.endBackgroundTask(task)
            task = .invalid
        }
        task = UIApplication.shared.beginBackgroundTask(withName: reason) { [weak self] in
            Task { @MainActor [weak self] in
                self?.end()
            }
        }

        // Re-assert silent audio if an interruption or route change stopped it.
        if isHosting, player?.isPlaying != true {
            activateAudioSession()
            startSilentPlayback()
        }
    }

    func end() {
        guard task != .invalid else { return }
        UIApplication.shared.endBackgroundTask(task)
        task = .invalid
    }

    // MARK: - Silent audio

    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // mixWithOthers: don't steal music / podcasts from the user.
            // playback + audio background mode: process stays runnable when locked.
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            // Fall back to background-task-only; WC wakes still get a short lease.
        }
    }

    private func startSilentPlayback() {
        if player == nil {
            do {
                let wav = Self.silentWAV()
                let audio = try AVAudioPlayer(data: wav)
                audio.numberOfLoops = -1
                // Near-silent: some iOS builds treat volume 0 as "not playing".
                audio.volume = 0.01
                audio.prepareToPlay()
                player = audio
            } catch {
                player = nil
                return
            }
        }
        guard let player, !player.isPlaying else { return }
        player.play()
    }

    private func tearDownAudio() {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
            self.interruptionObserver = nil
        }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
            self.routeObserver = nil
        }
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func observeAudioLifecycle() {
        guard interruptionObserver == nil else { return }
        let center = NotificationCenter.default
        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleInterruption(notification)
            }
        }
        routeObserver = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isHosting else { return }
                self.activateAudioSession()
                self.startSilentPlayback()
                self.extend(reason: "Rally audio route change")
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard isHosting else { return }
        let info = notification.userInfo ?? [:]
        let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt
        guard let typeValue, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        switch type {
        case .began:
            break
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) || options.isEmpty {
                activateAudioSession()
                startSilentPlayback()
                extend(reason: "Rally audio interruption ended")
            }
        @unknown default:
            break
        }
    }

    /// Minimal mono 16-bit PCM WAV (~1s of silence) — no bundled asset required.
    private static func silentWAV(sampleRate: Int = 8_000, durationSeconds: Double = 1.0) -> Data {
        let channels = 1
        let bitsPerSample = 16
        let numSamples = Int(Double(sampleRate) * durationSeconds)
        let dataSize = numSamples * channels * bitsPerSample / 8
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8

        var data = Data()
        data.reserveCapacity(44 + dataSize)

        func appendASCII(_ string: String) {
            data.append(contentsOf: string.utf8)
        }
        func appendUInt16(_ value: UInt16) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
        func appendUInt32(_ value: UInt32) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        appendASCII("RIFF")
        appendUInt32(UInt32(36 + dataSize))
        appendASCII("WAVE")
        appendASCII("fmt ")
        appendUInt32(16) // PCM fmt chunk size
        appendUInt16(1) // PCM
        appendUInt16(UInt16(channels))
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(byteRate))
        appendUInt16(UInt16(blockAlign))
        appendUInt16(UInt16(bitsPerSample))
        appendASCII("data")
        appendUInt32(UInt32(dataSize))
        data.append(Data(count: dataSize))
        return data
    }
}
