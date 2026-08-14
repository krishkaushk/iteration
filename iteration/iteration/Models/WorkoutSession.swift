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
    // Optional (not `= false`), since old Firestore documents don't have this key —
    // synthesized Decodable throws keyNotFound on a missing key even with a default
    // value declared, so Optional (decodes to nil) is what actually stays backward-compatible.
    var isDone: Bool? = nil
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
