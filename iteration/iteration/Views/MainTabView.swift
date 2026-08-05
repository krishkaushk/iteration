import SwiftUI

struct MainTabView: View {
    @Environment(\.selectedTab) private var selectedTab

    var body: some View {
        TabView(selection: selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            WorkoutView()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
                .tag(AppTab.workout)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(AppTab.history)

            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.progress)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(Color.appPrimary)
        .preferredColorScheme(.dark)
    }
}
