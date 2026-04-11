import HealthKit
import WatchKit

class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()

    let healthStore = HKHealthStore()
    var workoutSession: HKWorkoutSession?
    var workoutBuilder: HKLiveWorkoutBuilder?

    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isWorkoutActive = false
    @Published var isSessionActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var sessionMatchCount: Int = 0

    /// Tracks whether there's a currently active HKWorkoutActivity that needs ending
    private var hasActiveActivity = false

    // MARK: - Authorization

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("[WorkoutManager] Authorization failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Session Lifecycle

    /// Start a new session or resume an existing one (called when entering a match)
    func startOrResumeSession() {
        if let session = workoutSession {
            // Already have a workout session
            if isPaused {
                session.resume()
                isPaused = false
                // Begin a new activity segment for this match
                beginMatchActivity()
                if var state = SessionState.load() {
                    state.isPaused = false
                    state.matchCount += 1
                    state.save()
                    DispatchQueue.main.async {
                        self.sessionMatchCount = state.matchCount
                    }
                }
            }
            return
        }

        // Check if there's a today session state but no live workout session (app was killed)
        if let state = SessionState.load(), state.isToday {
            // Previous session lost due to app restart — start fresh workout, carry over count
            createWorkoutSession(existingMatchCount: state.matchCount + 1)
            return
        }

        // Brand new session
        createWorkoutSession(existingMatchCount: 1)
    }

    /// Legacy entry point — now delegates to startOrResumeSession
    func startWorkout() {
        startOrResumeSession()
    }

    /// Pause the session (match ended but session continues for next match)
    func pauseSession() {
        guard let session = workoutSession else { return }

        // Don't call endCurrentActivity here — doing so creates a gap between
        // the ended activity and the next beginNewActivity, which HealthKit
        // renders as a rest interval ("Unknown Goal" in Fitness).
        // Instead, we end + begin atomically in beginMatchActivity().
        session.pause()
        isPaused = true
        isSessionActive = true
        if var state = SessionState.load() {
            state.isPaused = true
            state.save()
        }
    }

    /// End the entire session (user manually ends today's practice)
    func endSession() {
        guard let session = workoutSession, let builder = workoutBuilder else {
            // Clean up orphaned SessionState
            SessionState.clear()
            DispatchQueue.main.async {
                self.isSessionActive = false
                self.isPaused = false
                self.sessionMatchCount = 0
            }
            return
        }

        // End the current activity segment before ending the session
        if hasActiveActivity {
            session.endCurrentActivity(on: Date())
            hasActiveActivity = false
        }

        session.end()

        builder.endCollection(withEnd: Date()) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                print("[WorkoutManager] End collection failed: \(error.localizedDescription)")
            }

            // Add aggregated metadata
            let records = MatchStore.shared.todayRecords()
            var metadata: [String: Any] = [
                "ShuttleScore_SessionMatches": records.count,
                "ShuttleScore_SessionType": "practice"
            ]
            for (i, record) in records.prefix(10).enumerated() {
                metadata["ShuttleScore_Match\(i+1)"] = "\(record.teamAName) vs \(record.teamBName) \(record.gamesWonByA)-\(record.gamesWonByB)"
            }

            builder.addMetadata(metadata) { _, error in
                if let error = error {
                    print("[WorkoutManager] Add metadata failed: \(error.localizedDescription)")
                }
            }

            builder.finishWorkout { workout, error in
                if let error = error {
                    print("[WorkoutManager] Finish workout failed: \(error.localizedDescription)")
                }
                if let workout = workout {
                    print("[WorkoutManager] Session ended: \(workout.duration)s, \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) kcal")
                }
            }

            DispatchQueue.main.async {
                self.isWorkoutActive = false
                self.isSessionActive = false
                self.isPaused = false
                self.sessionMatchCount = 0
                self.hasActiveActivity = false
                self.workoutSession = nil
                self.workoutBuilder = nil
                SessionState.clear()
            }
        }
    }

    /// Legacy end — now pauses session instead of ending
    func endWorkout(match: MatchState?) {
        pauseSession()
    }

    /// Check and recover session state on app launch
    func checkAndRecoverSession() {
        guard let state = SessionState.load() else {
            isSessionActive = false
            return
        }

        if !state.isToday {
            // Yesterday's session wasn't ended — clean up
            SessionState.clear()
            isSessionActive = false
            return
        }

        // Today's session exists (paused or running)
        isSessionActive = true
        isPaused = state.isPaused
        sessionMatchCount = state.matchCount
    }

    // MARK: - Private

    private func createWorkoutSession(existingMatchCount: Int) {
        guard !isWorkoutActive else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .badminton
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            session.delegate = self
            builder.delegate = self

            self.workoutSession = session
            self.workoutBuilder = builder

            let now = Date()

            session.startActivity(with: now)
            builder.beginCollection(withStart: now) { [weak self] success, error in
                if let error = error {
                    print("[WorkoutManager] Begin collection failed: \(error.localizedDescription)")
                }
                // Begin first match activity segment after collection starts
                self?.beginMatchActivity()
            }

            var state = SessionState()
            state.matchCount = existingMatchCount
            state.save()

            DispatchQueue.main.async {
                self.isWorkoutActive = true
                self.isSessionActive = true
                self.isPaused = false
                self.sessionMatchCount = existingMatchCount
            }
        } catch {
            print("[WorkoutManager] Failed to create workout session: \(error.localizedDescription)")
        }
    }

    /// Begin a new HKWorkoutActivity for the current match, so Fitness shows per-match stats.
    /// Ends the previous activity and immediately starts a new one to avoid rest-interval gaps.
    private func beginMatchActivity() {
        guard let session = workoutSession else { return }

        // End previous activity right before starting the new one — no time gap means
        // HealthKit won't insert a rest interval that shows as "Unknown Goal" in Fitness
        let now = Date()
        if hasActiveActivity {
            session.endCurrentActivity(on: now)
        }

        let config = HKWorkoutConfiguration()
        config.activityType = .badminton
        config.locationType = .indoor
        session.beginNewActivity(configuration: config, date: now, metadata: nil)
        hasActiveActivity = true
    }

    // MARK: - Helpers

    private func updateHeartRate(from statistics: HKStatistics) {
        guard let quantity = statistics.mostRecentQuantity() else { return }
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let value = quantity.doubleValue(for: heartRateUnit)
        DispatchQueue.main.async {
            self.heartRate = value
        }
    }

    private func updateActiveCalories(from statistics: HKStatistics) {
        guard let quantity = statistics.sumQuantity() else { return }
        let value = quantity.doubleValue(for: .kilocalorie())
        DispatchQueue.main.async {
            self.activeCalories = value
        }
    }

    private func updateElapsedTime() {
        guard let builder = workoutBuilder else { return }
        DispatchQueue.main.async {
            self.elapsedTime = builder.elapsedTime
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        print("[WorkoutManager] Session state: \(fromState.rawValue) -> \(toState.rawValue)")
        DispatchQueue.main.async {
            self.isWorkoutActive = (toState == .running)
            self.isPaused = (toState == .paused)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("[WorkoutManager] Session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // No-op for now
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            if let statistics = workoutBuilder.statistics(for: quantityType) {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    updateHeartRate(from: statistics)
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    updateActiveCalories(from: statistics)
                default:
                    break
                }
            }
        }

        updateElapsedTime()
    }
}
