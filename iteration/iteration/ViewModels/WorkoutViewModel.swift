import SwiftUI
import Observation

@Observable
final class WorkoutViewModel {
    var currentSession: WorkoutSession?
    var isActive: Bool { currentSession != nil }
    var selectedGym: Gym?
    var errorMessage: String?

    // Home stats
    var recentWorkouts: [WorkoutSession] = []

    func loadHomeData() async {
        do {
            recentWorkouts = try await FirestoreService.shared.fetchWorkouts(limit: 120)
        } catch {}
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

    // Rest timer (counts up)
    var restTimerElapsed: Int = 0
    var isRestTimerActive: Bool = false
    private var timerTask: Task<Void, Never>?

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
    }

    func toggleSetComplete(exerciseIndex: Int, setIndex: Int) {
        guard var session = currentSession,
              exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        session.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        currentSession = session

        if session.exercises[exerciseIndex].sets[setIndex].isCompleted {
            startRestTimer()
        }
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

    func startRestTimer() {
        timerTask?.cancel()
        restTimerElapsed = 0
        isRestTimerActive = true

        timerTask = Task { @MainActor in
            while isRestTimerActive {
                try? await Task.sleep(for: .seconds(1))
                if isRestTimerActive {
                    restTimerElapsed += 1
                }
            }
        }
    }

    func dismissRestTimer() {
        isRestTimerActive = false
        timerTask?.cancel()
        timerTask = nil
    }

    var restTimerFormatted: String {
        let minutes = restTimerElapsed / 60
        let seconds = restTimerElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
