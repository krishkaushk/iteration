import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    // Fixed for the whole workout — set once at startWorkout(), never mutated.
    var gymName: String?
    var workoutStartedAt: Date

    enum RestMode: String, Codable, Hashable {
        case countUp, countdown
    }

    // Mutates throughout the workout: current exercise/set progress, and rest-timer
    // fields that are only meaningful while `isResting` is true.
    struct ContentState: Codable, Hashable {
        var exerciseName: String
        var setNumber: Int
        var lastWeight: Double?
        var lastReps: Int?

        var isResting: Bool
        var restMode: RestMode
        var restStartedAt: Date?
        var restTargetSeconds: Int
        var restDidExpire: Bool
    }
}
