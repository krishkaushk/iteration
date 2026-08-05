import SwiftUI
import Observation

@Observable
final class ExerciseViewModel {
    var systemExercises: [Exercise] = []
    var customExercises: [Exercise] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedCategory: String?
    var selectedEquipmentType: String?

    var allExercises: [Exercise] {
        systemExercises + customExercises
    }

    var filteredExercises: [Exercise] {
        var results = allExercises

        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        if let equipment = selectedEquipmentType {
            results = results.filter { $0.equipmentType == equipment }
        }

        return results
    }

    func loadExercises() async {
        isLoading = true
        do {
            async let system = FirestoreService.shared.fetchSystemExercises()
            async let custom = FirestoreService.shared.fetchCustomExercises()
            systemExercises = try await system
            customExercises = try await custom
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addCustomExercise(name: String, category: String, equipmentType: String) async {
        let exercise = Exercise(
            name: name,
            category: category,
            equipmentType: equipmentType,
            isCustom: true
        )
        do {
            try await FirestoreService.shared.addCustomExercise(exercise)
            await loadExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func seedIfNeeded() async {
        do {
            try await FirestoreService.shared.seedSystemExercises()
            await loadExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
