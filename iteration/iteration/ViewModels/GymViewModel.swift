import SwiftUI
import Observation

@Observable
final class GymViewModel {
    var gyms: [Gym] = []
    var isLoading = false
    var isMutating = false
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
        var gym = Gym(name: name, location: location, createdAt: Date())
        isMutating = true
        do {
            gym.id = try await FirestoreService.shared.addGym(gym)
            gyms.append(gym)
        } catch {
            errorMessage = error.localizedDescription
        }
        isMutating = false
    }

    func deleteGym(_ gym: Gym) async {
        guard let id = gym.id else { return }
        let previousGyms = gyms
        gyms.removeAll { $0.id == id }
        isMutating = true
        do {
            try await FirestoreService.shared.deleteGym(id)
        } catch {
            gyms = previousGyms
            errorMessage = error.localizedDescription
        }
        isMutating = false
    }
}
