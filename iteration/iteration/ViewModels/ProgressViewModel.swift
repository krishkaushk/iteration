import Foundation
import Observation

struct StrengthPoint: Identifiable {
    var id = UUID()
    var date: Date
    var maxWeight: Double
}

struct VolumeBar: Identifiable {
    var id = UUID()
    var weekStart: Date
    var totalVolume: Double
}

@Observable
final class ProgressViewModel {
    var workouts: [WorkoutSession] = []
    var bodyWeightLogs: [BodyWeightLog] = []
    var selectedExerciseName: String = ""
    var newBodyWeight: Double = 0
    var isLoading = false
    var errorMessage: String?

    var exerciseNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for workout in workouts {
            for exercise in workout.exercises {
                if seen.insert(exercise.exerciseName).inserted {
                    names.append(exercise.exerciseName)
                }
            }
        }
        return names.sorted()
    }

    var strengthPoints: [StrengthPoint] {
        guard !selectedExerciseName.isEmpty else { return [] }
        return workouts.compactMap { session in
            let maxWeight = session.exercises
                .filter { $0.exerciseName == selectedExerciseName }
                .flatMap { $0.sets }
                .filter { $0.weight > 0 }
                .map { $0.weight }
                .max()
            guard let w = maxWeight else { return nil }
            return StrengthPoint(date: session.startedAt, maxWeight: w)
        }
        .sorted { $0.date < $1.date }
    }

    var weeklyVolumeBars: [VolumeBar] {
        let calendar = Calendar.current
        var volumeByWeek: [Date: Double] = [:]
        for workout in workouts {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.startedAt)
            guard let weekStart = calendar.date(from: components) else { continue }
            let allSets: [ExerciseSet] = workout.exercises.flatMap { $0.sets }
            let validSets = allSets.filter { $0.weight > 0 && $0.reps > 0 }
            let volume: Double = validSets.reduce(0.0) { acc, s in acc + s.weight * Double(s.reps) }
            volumeByWeek[weekStart, default: 0] += volume
        }
        return volumeByWeek
            .map { VolumeBar(weekStart: $0.key, totalVolume: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
            .suffix(12)
            .map { $0 }
    }

    // Body weight logs sorted oldest → newest for the chart
    var bodyWeightChartData: [BodyWeightLog] {
        bodyWeightLogs.reversed()
    }

    func load() async {
        isLoading = true
        do {
            workouts = try await FirestoreService.shared.fetchWorkouts(limit: 200)
            bodyWeightLogs = try await FirestoreService.shared.fetchBodyWeightLogs()
            if let first = exerciseNames.first, selectedExerciseName.isEmpty {
                selectedExerciseName = first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logBodyWeight() async {
        guard newBodyWeight > 0 else { return }
        let log = BodyWeightLog(date: Date(), weightLbs: newBodyWeight)
        do {
            try await FirestoreService.shared.saveBodyWeightLog(log)
            bodyWeightLogs.insert(log, at: 0)
            newBodyWeight = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
