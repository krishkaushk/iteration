import SwiftUI

struct MainTabView: View {
    @Environment(\.selectedTab) private var selectedTab
    @Environment(WorkoutViewModel.self) private var workoutVM

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
        .safeAreaInset(edge: .top) {
            if workoutVM.isActive && selectedTab.wrappedValue != .workout {
                activeWorkoutBanner
            }
        }
    }

    private var activeWorkoutBanner: some View {
        Button {
            selectedTab.wrappedValue = .workout
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 1) {
                    Text(workoutVM.currentSession?.gymName ?? "Workout in progress")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    if let startedAt = workoutVM.currentSession?.startedAt {
                        Text(startedAt, style: .timer)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appCardMaroonLight)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appCardMaroonLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appCardMaroon)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }
}
