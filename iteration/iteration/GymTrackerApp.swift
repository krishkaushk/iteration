import SwiftUI
import FirebaseCore

@main
struct GymTrackerApp: App {
    @State private var authViewModel: AuthViewModel
    @State private var workoutViewModel = WorkoutViewModel()
    @State private var selectedTab = AppTab.home

    init() {
        FirebaseApp.configure()
        _authViewModel = State(initialValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .environment(workoutViewModel)
                .environment(\.selectedTab, $selectedTab)
        }
    }
}

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<AppTab> = .constant(.home)
}

extension EnvironmentValues {
    var selectedTab: Binding<AppTab> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}
