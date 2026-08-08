import SwiftUI
import Observation
import FirebaseFirestore

@Observable
final class WorkoutViewModel {
    var currentSession: WorkoutSession?
    var isActive: Bool { currentSession != nil }
    var selectedGym: Gym?
    var errorMessage: String?

    // Home stats
    var recentWorkouts: [WorkoutSession] = []
    var isLoadingHomeData = false

    func loadHomeData() async {
        // Cache-first paint: shows last-known data instantly instead of blocking on
        // the server round trip, which can be slow on a cold Firestore connection.
        if let cached = try? await FirestoreService.shared.fetchWorkouts(limit: 120, source: .cache),
           !cached.isEmpty {
            recentWorkouts = cached
        }
        isLoadingHomeData = recentWorkouts.isEmpty
        do {
            recentWorkouts = try await FirestoreService.shared.fetchWorkouts(limit: 120, source: .server)
        } catch {}
        isLoadingHomeData = false
    }

    var workoutStreak: Int {
        let calendar = Calendar.current
        let workoutDays = Set(recentWorkouts.map { calendar.startOfDay(for: $0.startedAt) })
        var day = calendar.startOfDay(for: Date())
        if !workoutDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while workoutDays.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    var workoutsThisMonth: Int {
        let calendar = Calendar.current
        return recentWorkouts.filter {
            calendar.isDate($0.startedAt, equalTo: Date(), toGranularity: .month)
        }.count
    }

    var prsThisMonth: Int {
        let calendar = Calendar.current
        let thisMonth = recentWorkouts.filter {
            calendar.isDate($0.startedAt, equalTo: Date(), toGranularity: .month)
        }
        let before = recentWorkouts.filter {
            !calendar.isDate($0.startedAt, equalTo: Date(), toGranularity: .month)
        }
        let exercises = Set(thisMonth.flatMap { $0.exercises.map(\.exerciseName) })
        var prCount = 0
        for name in exercises {
            let thisExSets: [ExerciseSet] = thisMonth.flatMap { $0.exercises }
                .filter { $0.exerciseName == name }
                .flatMap { $0.sets }
            let prevExSets: [ExerciseSet] = before.flatMap { $0.exercises }
                .filter { $0.exerciseName == name }
                .flatMap { $0.sets }
            let thisMax: Double = thisExSets.map { $0.weight }.max() ?? 0
            let prevMax: Double = prevExSets.map { $0.weight }.max() ?? 0
            if thisMax > prevMax { prCount += 1 }
        }
        return prCount
    }

    // Returns [Bool] size 7 for Mon–Sun; true = had a workout that day this week
    var workoutMaskThisWeek: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return Array(repeating: false, count: 7)
        }
        let workoutDays = Set(recentWorkouts.map { calendar.startOfDay(for: $0.startedAt) })
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return false }
            return workoutDays.contains(day)
        }
    }

    // Rest timer — Date-based (not a manual counter) so display is always correct
    // from wall-clock math, including right after the app returns from the background.
    enum RestTimerMode {
        case countUp, countdown
    }
    var isRestTimerActive: Bool = false
    var restTimerStartedAt: Date?
    var restTimerMode: RestTimerMode = .countUp
    var restTimerTargetSeconds: Int = 90
    var restTimerExerciseIndex: Int?
    var restTimerSetIndex: Int?
    var restTimerDidExpire: Bool = false
    private var expiryTask: Task<Void, Never>?

    func startWorkout(gym: Gym? = nil) {
        currentSession = WorkoutSession(
            gymId: gym?.id,
            gymName: gym?.name,
            startedAt: Date(),
            exercises: []
        )
        selectedGym = gym
    }

    func repeatWorkout(from session: WorkoutSession) {
        var newExercises: [WorkoutExercise] = []
        for exercise in session.exercises {
            let newExercise = WorkoutExercise(
                id: UUID().uuidString,
                templateId: exercise.templateId,
                exerciseName: exercise.exerciseName,
                equipmentType: exercise.equipmentType,
                orderIndex: newExercises.count,
                sets: [
                    ExerciseSet(
                        id: UUID().uuidString,
                        setNumber: 1,
                        weight: exercise.sets.first?.weight ?? 0,
                        reps: exercise.sets.first?.reps ?? 0,
                        isCompleted: false,
                        createdAt: Date()
                    ),
                    // A ready-to-fill blank set right behind it, same as a freshly added exercise.
                    ExerciseSet(
                        id: UUID().uuidString,
                        setNumber: 2,
                        weight: exercise.sets.first?.weight ?? 0,
                        reps: 0,
                        isCompleted: false,
                        createdAt: Date()
                    )
                ]
            )
            newExercises.append(newExercise)
        }

        currentSession = WorkoutSession(
            gymId: session.gymId,
            gymName: session.gymName,
            startedAt: Date(),
            exercises: newExercises
        )
    }

    func addExercise(_ exercise: Exercise) {
        guard var session = currentSession else { return }
        let workoutExercise = WorkoutExercise(
            id: UUID().uuidString,
            templateId: exercise.id ?? UUID().uuidString,
            exerciseName: exercise.name,
            equipmentType: exercise.equipmentType,
            orderIndex: session.exercises.count,
            sets: [
                ExerciseSet(
                    id: UUID().uuidString,
                    setNumber: 1,
                    weight: 0,
                    reps: 0,
                    isCompleted: false,
                    createdAt: Date()
                )
            ]
        )
        session.exercises.append(workoutExercise)
        currentSession = session
        pruneSkeletons(except: session.exercises.count - 1)
    }

    /// Only the exercise you're actively working on should show a ready-to-fill
    /// skeleton set — once you move on to a new exercise, any other exercise's
    /// untouched trailing blank set goes away instead of lingering as clutter.
    private func pruneSkeletons(except keepIndex: Int) {
        guard var session = currentSession else { return }
        for i in session.exercises.indices where i != keepIndex {
            if let last = session.exercises[i].sets.last, last.reps == 0, !last.isCompleted {
                session.exercises[i].sets.removeLast()
            }
        }
        currentSession = session
    }

    func addSet(toExerciseAt index: Int) {
        guard var session = currentSession,
              index < session.exercises.count else { return }
        let nextSetNumber = session.exercises[index].sets.count + 1
        let newSet = ExerciseSet(
            id: UUID().uuidString,
            setNumber: nextSetNumber,
            weight: session.exercises[index].sets.last?.weight ?? 0,
            reps: session.exercises[index].sets.last?.reps ?? 0,
            isCompleted: false,
            createdAt: Date()
        )
        session.exercises[index].sets.append(newSet)
        currentSession = session
    }

    func updateSet(exerciseIndex: Int, setIndex: Int, weight: Double, reps: Int) {
        guard var session = currentSession,
              exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        session.exercises[exerciseIndex].sets[setIndex].weight = weight
        session.exercises[exerciseIndex].sets[setIndex].reps = reps
        currentSession = session
        ensureTrailingBlankSet(exerciseIndex: exerciseIndex)
    }

    func toggleSetComplete(exerciseIndex: Int, setIndex: Int) {
        guard var session = currentSession,
              exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        let set = session.exercises[exerciseIndex].sets[setIndex]
        // Can't complete a set with no reps logged — that's the untouched skeleton row.
        guard set.isCompleted || set.reps > 0 else { return }
        session.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        currentSession = session

        if session.exercises[exerciseIndex].sets[setIndex].isCompleted {
            startRestTimer(exerciseIndex: exerciseIndex, setIndex: setIndex)
        }
        ensureTrailingBlankSet(exerciseIndex: exerciseIndex)
    }

    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard var session = currentSession,
              exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        session.exercises[exerciseIndex].sets.remove(at: setIndex)
        for i in session.exercises[exerciseIndex].sets.indices {
            session.exercises[exerciseIndex].sets[i].setNumber = i + 1
        }
        currentSession = session
        ensureTrailingBlankSet(exerciseIndex: exerciseIndex)
    }

    /// Keeps exactly one ready-to-fill blank set at the end of an exercise, so the user
    /// always has a "next set" to tap into instead of pressing "Add set" every time.
    /// A set counts as blank once it has no reps and hasn't been marked complete —
    /// weight alone can legitimately be 0 for bodyweight exercises, so reps is the signal.
    private func ensureTrailingBlankSet(exerciseIndex: Int) {
        guard var session = currentSession, exerciseIndex < session.exercises.count else { return }
        let sets = session.exercises[exerciseIndex].sets
        guard let last = sets.last else { return }
        let lastIsBlank = last.reps == 0 && !last.isCompleted
        guard !lastIsBlank else { return }
        let newSet = ExerciseSet(
            id: UUID().uuidString,
            setNumber: sets.count + 1,
            weight: last.weight,
            reps: 0,
            isCompleted: false,
            createdAt: Date()
        )
        session.exercises[exerciseIndex].sets.append(newSet)
        currentSession = session
    }

    func removeExercise(at index: Int) {
        guard var session = currentSession else { return }
        session.exercises.remove(at: index)
        currentSession = session
    }

    func finishWorkout() async {
        guard var session = currentSession else { return }
        session.endedAt = Date()
        dismissRestTimer()
        do {
            try await FirestoreService.shared.saveWorkout(session)
            currentSession = nil
            selectedGym = nil
            await loadHomeData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelWorkout() {
        currentSession = nil
        selectedGym = nil
        dismissRestTimer()
    }

    // MARK: - Rest Timer

    func startRestTimer(exerciseIndex: Int, setIndex: Int) {
        finalizeRestTimer()

        expiryTask?.cancel()
        restTimerDidExpire = false
        restTimerStartedAt = Date()
        isRestTimerActive = true
        restTimerExerciseIndex = exerciseIndex
        restTimerSetIndex = setIndex

        if restTimerMode == .countdown {
            let target = restTimerTargetSeconds
            expiryTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(target))
                guard !Task.isCancelled else { return }
                restTimerDidExpire = true
            }
        }
    }

    func dismissRestTimer() {
        finalizeRestTimer()
        isRestTimerActive = false
        restTimerStartedAt = nil
        restTimerExerciseIndex = nil
        restTimerSetIndex = nil
        restTimerDidExpire = false
        expiryTask?.cancel()
        expiryTask = nil
    }

    /// Logs how long the just-finished rest period lasted onto the set that follows
    /// the one which triggered it — that set is guaranteed to exist because of the
    /// skeleton invariant (`ensureTrailingBlankSet`). Called both when a new rest
    /// timer is about to replace this one (moved straight to the next set) and when
    /// the user explicitly dismisses it.
    private func finalizeRestTimer() {
        guard isRestTimerActive,
              let startedAt = restTimerStartedAt,
              let exIndex = restTimerExerciseIndex,
              let setIndex = restTimerSetIndex,
              var session = currentSession,
              exIndex < session.exercises.count,
              setIndex + 1 < session.exercises[exIndex].sets.count
        else { return }
        let elapsed = Int(Date().timeIntervalSince(startedAt))
        session.exercises[exIndex].sets[setIndex + 1].restSeconds = elapsed
        currentSession = session
    }
}
