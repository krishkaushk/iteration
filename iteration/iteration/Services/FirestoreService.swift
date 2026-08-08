import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    private func userDoc() throws -> DocumentReference {
        guard let uid = userId else { throw FirestoreError.notAuthenticated }
        return db.collection("users").document(uid)
    }

    // MARK: - Gyms

    func fetchGyms() async throws -> [Gym] {
        let snapshot = try await userDoc().collection("gyms")
            .order(by: "createdAt", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Gym.self) }
    }

    func addGym(_ gym: Gym) async throws -> String {
        let ref = try userDoc().collection("gyms").addDocument(from: gym)
        return ref.documentID
    }

    func deleteGym(_ gymId: String) async throws {
        try await userDoc().collection("gyms").document(gymId).delete()
    }

    // MARK: - Exercises (system library)

    func fetchSystemExercises() async throws -> [Exercise] {
        let snapshot = try await db.collection("systemExercises")
            .order(by: "name")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Exercise.self) }
    }

    // MARK: - Custom Exercises

    func fetchCustomExercises() async throws -> [Exercise] {
        let snapshot = try await userDoc().collection("exerciseTemplates")
            .order(by: "name")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Exercise.self) }
    }

    func addCustomExercise(_ exercise: Exercise) async throws {
        try userDoc().collection("exerciseTemplates").addDocument(from: exercise)
    }

    // MARK: - Workout Sessions

    func saveWorkout(_ session: WorkoutSession) async throws {
        try userDoc().collection("workoutSessions").addDocument(from: session)
    }

    func fetchWorkouts(limit: Int = 20, source: FirestoreSource = .default) async throws -> [WorkoutSession] {
        let snapshot = try await userDoc().collection("workoutSessions")
            .order(by: "startedAt", descending: true)
            .limit(to: limit)
            .getDocuments(source: source)
        return snapshot.documents.compactMap { try? $0.data(as: WorkoutSession.self) }
    }

    // MARK: - Body Weight Logs

    func saveBodyWeightLog(_ log: BodyWeightLog) async throws {
        try userDoc().collection("bodyWeightLogs").addDocument(from: log)
    }

    func fetchBodyWeightLogs(limit: Int = 90, source: FirestoreSource = .default) async throws -> [BodyWeightLog] {
        let snapshot = try await userDoc().collection("bodyWeightLogs")
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments(source: source)
        return snapshot.documents.compactMap { try? $0.data(as: BodyWeightLog.self) }
    }

    // MARK: - User Settings

    private func settingsDoc() throws -> DocumentReference {
        try userDoc().collection("profile").document("settings")
    }

    func fetchUserSettings() async throws -> UserSettings {
        let snapshot = try await settingsDoc().getDocument()
        return (try? snapshot.data(as: UserSettings.self)) ?? UserSettings()
    }

    func updateMonthlyGoal(_ goal: Int) async throws {
        try settingsDoc().setData(from: UserSettings(monthlyGoal: goal), merge: true)
    }

    // MARK: - Seed System Exercises

    func seedSystemExercises() async throws {
        let existingSnapshot = try await db.collection("systemExercises").getDocuments()
        let existingExercises: [Exercise] = existingSnapshot.documents.compactMap { try? $0.data(as: Exercise.self) }
        let existingNames: Set<String> = Set(existingExercises.map { $0.name })

        let exercises: [(String, String, String)] = [
            // Chest
            ("Bench Press", "chest", "barbell"),
            ("Incline Bench Press", "chest", "barbell"),
            ("Decline Bench Press", "chest", "barbell"),
            ("DB Bench Press", "chest", "dumbbell"),
            ("DB Incline Bench Press", "chest", "dumbbell"),
            ("DB Fly", "chest", "dumbbell"),
            ("Smith Machine Bench Press", "chest", "machine"),
            ("Smith Machine Incline Bench Press", "chest", "machine"),
            ("Machine Chest Press", "chest", "machine"),
            ("Chest Fly Machine", "chest", "machine"),
            ("Cable Fly", "chest", "cable"),
            ("Cable Crossover", "chest", "cable"),
            ("Push-up", "chest", "bodyweight"),
            ("Dip", "chest", "bodyweight"),

            // Back
            ("Deadlift", "back", "barbell"),
            ("Barbell Row", "back", "barbell"),
            ("Pendlay Row", "back", "barbell"),
            ("Barbell Shrug", "back", "barbell"),
            ("DB Row", "back", "dumbbell"),
            ("DB Shrug", "back", "dumbbell"),
            ("T-Bar Row", "back", "machine"),
            ("Seated Row Machine", "back", "machine"),
            ("Chest-Supported Row", "back", "machine"),
            ("Lat Pulldown", "back", "machine"),
            ("Close-Grip Lat Pulldown", "back", "machine"),
            ("Reverse-Grip Lat Pulldown", "back", "machine"),
            ("Cable Row - Wide Grip", "back", "cable"),
            ("Cable Row - Close Grip", "back", "cable"),
            ("Pull-up", "back", "bodyweight"),
            ("Chin-up", "back", "bodyweight"),

            // Legs
            ("Squat", "legs", "barbell"),
            ("Front Squat", "legs", "barbell"),
            ("Romanian Deadlift", "legs", "barbell"),
            ("Sumo Deadlift", "legs", "barbell"),
            ("Hip Thrust", "legs", "barbell"),
            ("Goblet Squat", "legs", "dumbbell"),
            ("Bulgarian Split Squat", "legs", "dumbbell"),
            ("Walking Lunge", "legs", "dumbbell"),
            ("Reverse Lunge", "legs", "dumbbell"),
            ("Step-Up", "legs", "dumbbell"),
            ("Leg Press", "legs", "machine"),
            ("Hack Squat", "legs", "machine"),
            ("Leg Curl", "legs", "machine"),
            ("Leg Extension", "legs", "machine"),
            ("Standing Calf Raise", "legs", "machine"),
            ("Seated Calf Raise", "legs", "machine"),
            ("Hip Abductor Machine", "legs", "machine"),
            ("Hip Adductor Machine", "legs", "machine"),
            ("Glute Bridge", "legs", "bodyweight"),

            // Shoulders
            ("Overhead Press", "shoulders", "barbell"),
            ("DB Shoulder Press", "shoulders", "dumbbell"),
            ("Lateral Raise", "shoulders", "dumbbell"),
            ("Machine Shoulder Press", "shoulders", "machine"),
            ("Cable Lateral Raise", "shoulders", "cable"),
            ("Face Pull", "shoulders", "cable"),

            // Arms
            ("EZ Bar Curl", "arms", "barbell"),
            ("Preacher Curl", "arms", "barbell"),
            ("Reverse Curl", "arms", "barbell"),
            ("Close-Grip Bench Press", "arms", "barbell"),
            ("Skullcrusher", "arms", "barbell"),
            ("DB Curl", "arms", "dumbbell"),
            ("Hammer Curl", "arms", "dumbbell"),
            ("Concentration Curl", "arms", "dumbbell"),
            ("Tricep Kickback", "arms", "dumbbell"),
            ("Overhead Tricep Extension", "arms", "dumbbell"),
            ("Cable Curl", "arms", "cable"),
            ("Tricep Pushdown", "arms", "cable"),
            ("Cable Overhead Tricep Extension", "arms", "cable"),
            ("Bench Dip", "arms", "bodyweight"),

            // Core
            ("Russian Twist", "core", "dumbbell"),
            ("Cable Woodchopper", "core", "cable"),
            ("Plank", "core", "bodyweight"),
            ("Side Plank", "core", "bodyweight"),
            ("Sit-up", "core", "bodyweight"),
            ("Crunch", "core", "bodyweight"),
            ("Bicycle Crunch", "core", "bodyweight"),
            ("Hanging Leg Raise", "core", "bodyweight"),
            ("Ab Wheel Rollout", "core", "bodyweight"),
            ("Mountain Climbers", "core", "bodyweight"),
            ("Dead Bug", "core", "bodyweight"),
            ("V-Up", "core", "bodyweight"),
        ]

        let missingExercises = exercises.filter { !existingNames.contains($0.0) }
        guard !missingExercises.isEmpty else { return }

        let batch = db.batch()
        for (name, category, equipment) in missingExercises {
            let ref = db.collection("systemExercises").document()
            let exercise = Exercise(
                name: name,
                category: category,
                equipmentType: equipment,
                isCustom: false
            )
            try batch.setData(from: exercise, forDocument: ref)
        }
        try await batch.commit()
    }
}

enum FirestoreError: Error {
    case notAuthenticated
}
