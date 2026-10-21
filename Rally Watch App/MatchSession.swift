import HealthKit

/// A HealthKit workout that records behind the scoreboard.
@MainActor
@Observable
final class MatchSession: NSObject {
    private let healthStore = HKHealthStore()
    private let defaults: UserDefaults
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var clock: Timer?
    private var collectionStarted = false
    private var shouldSave = false
    private var scoreMetadata: [String: Any]?

    private(set) var isRunning = false
    private(set) var isStarting = false
    private(set) var isEnding = false
    var elapsed: TimeInterval = 0
    var heartRate: Double?
    var errorMessage: String?

    var activityType: HKWorkoutActivityType {
        didSet { persistActivityType() }
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    init(suiteName: String = ScoreDefaults.suiteName) {
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let raw = defaults.object(forKey: ScoreDefaults.workoutActivityTypeKey) as? UInt
        if let raw, let saved = HKWorkoutActivityType(rawValue: raw) {
            activityType = saved
        } else {
            activityType = .volleyball
        }
        super.init()
    }

    func startWorkout() async {
        guard !isRunning, !isStarting, session == nil else { return }
        guard isAvailable else {
            errorMessage = "Health data isn’t available on this watch."
            return
        }

        isStarting = true
        defer { isStarting = false }

        do {
            try await authorize()
            try await beginSession(activityType: activityType)
        } catch {
            session?.end()
            session = nil
            builder = nil
            errorMessage = error.localizedDescription
        }
    }

    func endMatch(homeScore: Int, awayScore: Int, homeName: String, awayName: String) {
        guard let session, !isEnding else { return }
        isEnding = true
        shouldSave = true
        scoreMetadata = [
            "com.ItWasMattGregg.Rally.homeScore": homeScore,
            "com.ItWasMattGregg.Rally.awayScore": awayScore,
            "com.ItWasMattGregg.Rally.homeName": homeName,
            "com.ItWasMattGregg.Rally.awayName": awayName
        ]
        session.end()
    }

    static func clockString(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func persistActivityType() {
        defaults.set(activityType.rawValue, forKey: ScoreDefaults.workoutActivityTypeKey)
    }

    private func authorize() async throws {
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned)
        ]
        try await healthStore.requestAuthorization(toShare: share, read: read)
        guard healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else {
            throw MatchSessionError.notAuthorized
        }
    }

    private func beginSession(activityType: HKWorkoutActivityType) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = activityType.rallyLocationType
        if let swimmingLocation = activityType.rallySwimmingLocationType {
            configuration.swimmingLocationType = swimmingLocation
        }

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        session.delegate = self
        builder.delegate = self

        self.session = session
        self.builder = builder

        let start = Date()
        session.startActivity(with: start)
        try await builder.beginCollection(at: start)
        collectionStarted = true
        isRunning = true
        elapsed = 0
        heartRate = nil
        startClock()
    }

    private func startClock() {
        clock?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickClock()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        clock = timer
    }

    private func tickClock() {
        elapsed = builder?.elapsedTime ?? elapsed
    }

    private func handle(_ state: HKWorkoutSessionState, date: Date) {
        switch state {
        case .running:
            isRunning = true
            if clock == nil { startClock() }
        case .ended:
            clock?.invalidate()
            clock = nil
            Task { await finalize(at: date) }
        default:
            break
        }
    }

    private func finalize(at date: Date) async {
        defer { reset() }
        guard collectionStarted, let builder else { return }
        do {
            try await builder.endCollection(at: date)
            guard shouldSave else { return }
            if let scoreMetadata {
                try await builder.addMetadata(scoreMetadata)
            }
            try await finish(builder)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finish(_ builder: HKLiveWorkoutBuilder) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.finishWorkout { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func reset() {
        session = nil
        builder = nil
        collectionStarted = false
        shouldSave = false
        scoreMetadata = nil
        isRunning = false
        isStarting = false
        isEnding = false
        heartRate = nil
    }
}

extension MatchSession: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            self.handle(toState, date: date)
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.errorMessage = message
            self.isRunning = false
            self.isStarting = false
        }
    }
}

extension MatchSession: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let heartRateType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRateType) else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        guard let bpm = workoutBuilder.statistics(for: heartRateType)?
            .mostRecentQuantity()?
            .doubleValue(for: unit) else { return }
        Task { @MainActor in
            self.heartRate = bpm
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        let elapsed = workoutBuilder.elapsedTime
        Task { @MainActor in
            self.elapsed = elapsed
        }
    }
}

private enum MatchSessionError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            "Allow Rally to save workouts in Health to record a match."
        }
    }
}
