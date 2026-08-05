import SwiftUI
import FirebaseAuth
import Observation

@Observable
final class AuthViewModel {
    var user: FirebaseAuth.User? = nil
    var isLoading = false
    var errorMessage: String? = nil
    var isCheckingAuth = true
    var monthlyGoal: Int = 20

    var isAuthenticated: Bool { user != nil }

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isCheckingAuth = false
            if user != nil {
                Task { await self?.loadUserSettings() }
            }
        }
    }

    func loadUserSettings() async {
        guard let settings = try? await FirestoreService.shared.fetchUserSettings() else { return }
        monthlyGoal = settings.monthlyGoal
    }

    func updateMonthlyGoal(_ goal: Int) async {
        monthlyGoal = goal
        try? await FirestoreService.shared.updateMonthlyGoal(goal)
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}
