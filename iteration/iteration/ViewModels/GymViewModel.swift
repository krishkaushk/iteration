import SwiftUI
import Observation

@Observable
final class GymViewModel {
    var gyms: [Gym] = []
    var isLoading = false
    var errorMessage: String?

    func loadGyms() async {
        isLoading = true
        do {
            gyms = try await FirestoreService.shared.fetchGyms()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addGym(name: String, location: String) async {
        let gym = Gym(name: name, location: location, createdAt: Date())
        do {
            try await FirestoreService.shared.addGym(gym)
            await loadGyms()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteGym(_ gym: Gym) async {
        guard let id = gym.id else { return }
        do {
            try await FirestoreService.shared.deleteGym(id)
            await loadGyms()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
