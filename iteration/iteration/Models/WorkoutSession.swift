import Foundation
import FirebaseFirestore

struct WorkoutSession: Codable, Identifiable {
    @DocumentID var id: String?
    var gymId: String?
    var gymName: String?
    var startedAt: Date
    var endedAt: Date?
    var notes: String?
    var exercises: [WorkoutExercise]
}

struct WorkoutExercise: Codable, Identifiable {
    var id: String
    var templateId: String
    var exerciseName: String
    var equipmentType: String
    var variantId: String?
    var orderIndex: Int
    var sets: [ExerciseSet]
}

struct ExerciseSet: Codable, Identifiable {
    var id: String
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var rpe: Double?
    var notes: String?
    var restSeconds: Int?
    var createdAt: Date
}
